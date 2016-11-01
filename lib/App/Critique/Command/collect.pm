package App::Critique::Command::collect;

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny      ();
use Term::ANSIColor ':constants';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'root=s',        'directory to start traversal from (default is root of git work tree)' ],
        [],
        [ 'no-violation',  'filter files that contain no Perl::Critic violations ' ],
        [],
        [ 'filter|f=s',    'filter files to remove with this regular expression' ],
        [ 'match|m=s',     'match files to keep with this regular expression' ],
        [],
        [ 'ignore-errors', 'when matching or filtering, ignore any errors that occur when testing a file (ex: Perl::Critic parse errors)' ],
        [],
        [ 'dry-run',       'display list of files, but do not store them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

our $PAUSE_PROCESSING = 0;

sub execute {
    my ($self, $opt, $args) = @_;

    local $Term::ANSIColor::AUTORESET = 1;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my $root = $opt->root
        ? Path::Tiny::path( $opt->root )
        : $session->git_work_tree;

    my $git_root       = $session->git_work_tree_root;
    my $file_predicate = generate_file_predicate(
        $session => (
            filter       => $opt->filter,
            match        => $opt->match,
            no_violation => $opt->no_violation
        )
    );

    my @all;
    eval {
        local $SIG{INT} = sub { $PAUSE_PROCESSING++ };
        
        find_all_perl_files(
            root        => $git_root,
            path        => $root,
            accumulator => \@all,
        );
        my $unfiltered_count = scalar @all;
        info('Accumulated %d files, now processing', $unfiltered_count);
        
        filter_files_serially( 
            root   => $git_root,
            files  => \@all,
            filter => $file_predicate
        );
        my $filtered_count = scalar @all;
        info('Filtered %d files, left with %d', $unfiltered_count - $filtered_count, $filtered_count);
        
        1;
    } or do {
        my $e = $@;
        die $e;
    };

    my $num_files = scalar @all;
    info('Collected %d perl file(s) for critique.', $num_files);

    foreach my $file ( @all ) {
        info(
            ITALIC('Including %s'),
            Path::Tiny::path( $file )->relative( $git_root )
        );
    }

    if ( $opt->verbose && $opt->no_violation ) {
        my $stats = $session->perl_critic->statistics;
        info(HR_DARK);
        info('STATISTICS(Perl::Critic)');
        info(HR_LIGHT);
        info(BOLD('VIOLATIONS   : %s'), format_number($stats->total_violations));
        info('== PERL '.('=' x (TERM_WIDTH() - 8)));
        info('  modules    : %s', format_number($stats->modules));
        info('  subs       : %s', format_number($stats->subs));
        info('  statements : %s', format_number($stats->statements));
        info('== LINES '.('=' x (TERM_WIDTH() - 9)));
        info(BOLD('TOTAL        : %s'), format_number($stats->lines));
        info('  perl       : %s', format_number($stats->lines_of_perl));
        info('  pod        : %s', format_number($stats->lines_of_pod));
        info('  comments   : %s', format_number($stats->lines_of_comment));
        info('  data       : %s', format_number($stats->lines_of_data));
        info('  blank      : %s', format_number($stats->lines_of_blank));
        info(HR_DARK);
    }

    if ( $opt->dry_run ) {
        info('[dry run] %s file(s) found, 0 files added.', format_number($num_files));
    }
    else {
        $session->set_tracked_files( @all );
        $session->reset_file_idx;
        info('Sucessfully added %s file(s).', format_number($num_files));

        $self->cautiously_store_session( $session, $opt, $args );
        info('Session file stored successfully (%s).', $session->session_file_path);
    }
}

sub filter_files_serially {
    my %args   = @_;
    my $root   = $args{root}; # the reason for `root` is to pass to the filter
    my $all    = $args{files};
    my $filter = $args{filter};
    
    my @filtered_all;
    while ( @$all ) {
        if ( $PAUSE_PROCESSING ) {
            warning('[processing paused]');

        PROMPT:
            my $continue = prompt_str(
                '>> (r)esume (h)alt (a)bort | (s)tatus ',
                {
                    valid   => sub { $_[0] =~ m/[rhas]{1}/ },
                    default => 'r',
                }
            );

            if ( $continue eq 'r' ) {
                warning('[resuming]');
                $PAUSE_PROCESSING = 0;
            }
            elsif ( $continue eq 'h' ) {
                warning('[abort processing - partial pruning]');
                last;
            }
            elsif ( $continue eq 'a' ) {
                warning('[abort processing - results discarded]');
                @filtered_all = ();
                last;
            }
            elsif ( $continue eq 's' ) {
                warning( join "\n" => @filtered_all );
                warning('[Accumulated %d files so far]', scalar @filtered_all );
                goto PROMPT;
            }
        }
        
        my $path = shift @$all;
        
        info('Processing file %s', $path);
        if ( $filter->( $root, $path ) ) {
            info(BOLD('Keeping file %s'), $path);
            push @filtered_all => $path;
        }
    }
    
    @$all = @filtered_all;
}

sub find_all_perl_files {   
    my %args = @_;
    my $root = $args{root}; # the reason for `root` is to have nicer output (just FYI)
    my $path = $args{path};
    my $acc  = $args{accumulator};

    if ( $path->is_file ) {
        # ignore anything but perl files ...
        return unless is_perl_file( $path->stringify );

        info('... adding file (%s)', $path->relative( $root )); # this should be the only usafe of root
        push @$acc => $path;
    }
    elsif ( -l $path ) { # Path::Tiny does not have a test for symlinks
        ;
    }
    else {
        my @children = $path->children( qr/^[^.]/ );

        # prune the directories we really don't care about
        if ( my $ignore = $App::Critique::CONFIG{'IGNORE'} ) {
            @children = grep !$ignore->{ $_->basename }, @children;
        }

        # recurse ...
         foreach my $child ( @children ) {
            find_all_perl_files(
                root          => $root,
                path          => $child,
                accumulator   => $acc,
            );
        }
    }

    return;
}

sub generate_file_predicate {
    my ($session, %args) = @_;

    my $filter       = $args{filter};
    my $match        = $args{match};
    my $no_violation = $args{no_violation};

    my $c = $session->perl_critic;

    # lets build an array of code_ref filters, that will be use to filter
    # the files, the code refs assume the params will be $path,$rel.

    #-------------------------------#
    # match | filter | no-violation #
    #-------------------------------#
    #    1  |    1   |      1       # collect with match, filter and no violations
    #    1  |    1   |      0       # collect with match and filter
    #    1  |    0   |      1       # collect with match and no violations
    #    1  |    0   |      0       # collect with match
    #-------------------------------#
    #    0  |    1   |      1       # collect with filter and no violations
    #    0  |    1   |      0       # collect with filter
    #-------------------------------#
    #    0  |    0   |      1       # collect with no violations
    #-------------------------------#
    #    0  |    0   |      0       # collect
    #-------------------------------#

    my @filters = (sub { return 1 });
    push @filters, sub { return $_[1] =~ /$match/ } if $match ;
    push @filters, sub { return $_[1] !~ /$filter/} if $filter;
    push @filters, sub {
        return scalar $c->critique( $_[0]->stringify )
    }  if $no_violation;

    my $predicate = sub {
        my ($root,$path) = @_;
        my $rel = $path->relative( $root );
        for my $file_filter( @filters ) {
            return unless $file_filter->($path,$rel);
        }
        return 1;
    };

    $session->set_file_criteria({
        filter       => $filter,
        match        => $match,
        no_violation => $no_violation
    });

    return $predicate;
}

# NOTE:
# This was mostly taken from the guts of
# Perl::Critic::Util::{_is_perl,_is_backup}
# - SL
sub is_perl_file {
    my ($file) = @_;

    # skip all the backups
    return 0 if $file =~ m{ [.] swp \z}xms;
    return 0 if $file =~ m{ [.] bak \z}xms;
    return 0 if $file =~ m{  ~ \z}xms;
    return 0 if $file =~ m{ \A [#] .+ [#] \z}xms;

    # but grab the perl files
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;
    return 1 if $file =~ m{ [.] psgi  \z}xms;
    return 1 if $file =~ m{ [.] cgi   \z}xms;

    # if we have to, check for shebang
    my $first;
    {
        open my $fh, '<', $file or return 0;
        $first = <$fh>;
        close $fh;
    }

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return 0;
}

1;

__END__

# ABSTRACT: Collect set of files for current critique session

=pod

=head1 DESCRIPTION

This command will traverse the critque directory and gather all available Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

It should be noted that this is a destructive command, meaning that if you have
begun critiquing your files and you re-run this command it will overwrite that
list and you will loose any tracking information you currently have.

=cut
