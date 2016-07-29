package App::Critique::Command::collect;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny ();
use List::Util ();

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'root=s',       'directory to start traversal from (default is root of git work tree)' ],
        [],
        [ 'no-violation', 'filter files that contain no Perl::Critic violations ' ],
        [],
        [ 'filter|f=s',   'filter files to remove with this regular expression' ],
        [ 'match|m=s',    'match files to keep with this regular expression' ],
        [],
        [ 'shuffle',      'shuffle the file list' ],
        [],
        [ 'dry-run',      'display list of files, but do not store them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my $root = $opt->root
        ? Path::Tiny::path( $opt->root )
        : $session->git_work_tree;

    # this is a match predicate, it
    # should return true if we want
    # to kepe the file
    my $predicate;

    # ------------------------------#
    # filter | match | no-violation #
    # ------------------------------#
    #    1   |   0   |      0       |
    #    1   |   1   |      0       |
    #    1   |   1   |      1       |
    #    0   |   1   |      1       |
    #    0   |   0   |      1       |
    #    0   |   0   |      0       |
    # ------------------------------#

    # filter only
    if ( $opt->filter && not($opt->match) && not($opt->no_violation) ) {
        my $f = $opt->filter;
        $predicate = sub {
            my $path = $_[0];
            return $path !~ /$f/;
        };
    }
    # filter and match
    elsif ( $opt->filter && $opt->match && not($opt->no_violation) ) {
        my $m = $opt->match;
        my $f = $opt->filter;
        $predicate = sub {
            my $path = $_[0];
            return $path =~ /$m/
                && $path !~ /$f/;
        };
    }
    # filter and match and check violations
    elsif ( $opt->filter && $opt->match && $opt->no_violation ) {
        my $m = $opt->match;
        my $f = $opt->filter;
        my $c = $session->perl_critic;
        $predicate = sub {
            my $path = $_[0];
            return $path =~ /$m/
                && $path !~ /$f/
                && (0 == scalar $c->critique( $path ));
        };
    }
    # match and check violations
    elsif ( not($opt->filter) && $opt->match && $opt->no_violation ) {
        my $m = $opt->match;
        my $c = $session->perl_critic;
        $predicate = sub {
            my $path = $_[0];
            return $path =~ /$m/
                && (0 == scalar $c->critique( $path ));
        };
    }
    # match only
    elsif ( not($opt->filter) && $opt->match && not($opt->no_violation) ) {
        my $m = $opt->match;
        $predicate = sub {
            my $path = $_[0];
            return $path =~ /$m/;
        };
    }
    # check violations only
    elsif ( not($opt->filter) && not($opt->match) && $opt->no_violation ) {
        my $c = $session->perl_critic;
        $predicate = sub {
            my $path = $_[0];
            return 0 == scalar $c->critique( $path );
        };
    }
    # none of the above
    else {
        $predicate = sub () { 1 };
    }

    my @all;
    traverse_filesystem(
        root        => $root,
        path        => $root,
        predicate   => $predicate,
        accumulator => \@all,
        verbose     => 1,
    );

    my $num_files = scalar @all;
    info('Collected %d perl file(s) for critique.', $num_files);

    if ( $opt->shuffle ) {
        info('Shuffling file list.');
        @all = List::Util::shuffle( @all );
    }

    foreach my $file ( @all ) {
        info(
            'Including %s',
            Path::Tiny::path( $file )->relative( $session->git_work_tree )
        );
    }

    if ( $opt->dry_run ) {
        info('[dry run] %d file(s) found, 0 files added.', $num_files);
    }
    else {
        $session->set_tracked_files( @all );
        info('Sucessfully added %d file(s).', $num_files);

        $self->cautiously_store_session( $session, $opt, $args );
        info('Session file stored successfully (%s).', $session->session_file_path);
    }
}

sub traverse_filesystem {
    my %args      = @_;
    my $root      = $args{root};
    my $path      = $args{path};
    my $predicate = $args{predicate};
    my $acc       = $args{accumulator};
    my $verbose   = $args{verbose};

    if ( $path->is_file ) {
        # ignore anything but perl files ...
        return unless is_perl_file( $path->stringify );

        # only accept things that match the
        # predicate on the relative root
        my $rel_path = $path->relative( $root );
        if ( $predicate->( $rel_path ) ) {
            info('Matched: keeping file (%s)', $rel_path) if $verbose;
            push @$acc => $path;
        }
        else {
            info('Not Matched: skipping file (%s)', $rel_path) if $verbose;
        }
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
        traverse_filesystem(
            root        => $root,
            path        => $_,
            predicate   => $predicate,
            accumulator => $acc,
            verbose     => $verbose,
        ) foreach @children;
    }

    return;
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

=head1 NAME

App::Critique::Command::collect - Collect set of files for current critique session

=head1 DESCRIPTION

This command will traverse the critque directory and gather all available Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

It should be noted that this is a destructive command, meaning that if you have
begun critiquing your files and you re-run this command it will overwrite that
list and you will loose any tracking information you currently have.

=cut
