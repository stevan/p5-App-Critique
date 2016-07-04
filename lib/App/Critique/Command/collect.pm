package App::Critique::Command::collect;

use strict;
use warnings;

use List::Util ();

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'root=s',     'directory to start traversal from (default is root of git work tree)' ],
        [],
        [ 'filter|f=s', 'filter the files with this regular expression' ],
        [ 'invert|i',   'invert the results of the filter' ],
        [],
        [ 'shuffle',    'shuffle the file list' ],
        [],
        [ 'dry-run',    'display list of files, but do not store them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = App::Critique::Session->locate_session(
        sub { $self->handle_session_file_exception('load', @_, $opt->debug) }
    );

    if ( $session ) {

        info('Session file located.');

        my $root = $opt->root
            ? Path::Class::Dir->new( $opt->root )
            : $session->git_work_tree;

        my $filter;
        if ( my $f = $opt->filter ) {
            if ( ref $f eq 'CODE' ) {
                $filter = $f;
            }
            else {
                $filter = $opt->invert
                    ? sub { $_[0]->stringify !~ /$f/ }
                    : sub { $_[0]->stringify =~ /$f/ };
            }
        }

        my @all;
        traverse_filesystem(
            $root,
            $filter,
            sub { push @all => $_[0] },
        );

        my $num_files = scalar @all;
        info('Collected %d perl files for critique.', $num_files);

        if ( $opt->shuffle ) {
            info('Shuffling file list.');
            @all = List::Util::shuffle( @all );
        }

        if ( $opt->verbose ) {
            foreach my $file ( @all ) {
                info(
                    'Including %s',
                    Path::Class::File->new( $file )->relative( $session->git_work_tree )
                );
            }
        }

        if ( $opt->dry_run ) {
            info('[dry run] %d files found, 0 files added.', $num_files);
        }
        else {
            $session->set_files_to_track( @all );
            info('Sucessfully added %d files.', $num_files);
            $session->store;
            info('Session file stored successfully (%s).', $session->session_file_path);
        }
    }
    else {
        if ( $opt->verbose ) {
            warning(
                'Unable to locate session file, looking for (%s)',
                App::Critique::Session->locate_session_file // 'undef'
            );
        }
        error('No session file found, perhaps you forgot to call `init`.');
    }
}


my %SKIP = map { ($_ => 1) } qw[  CVS RCS .svn _darcs {arch} .bzr .cdv .git .hg .pc _build blib  ];

sub traverse_filesystem {
    my ($dir, $filter, $v) = @_;

    if ( -f $dir ) {
        return unless is_perl_file( $dir );
        return if defined $filter && $filter->( $dir );
        $v->( $dir );
    }
    elsif ( -l $dir ) {
        ;
    }
    else {
        my @children = $dir->children( no_hidden => 1 );
        # prune the directories we really don't care about
        @children = grep !$SKIP{ $_->basename }, @children;
        # recurse ...
        map traverse_filesystem( $_, $filter, $v ), @children;
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
