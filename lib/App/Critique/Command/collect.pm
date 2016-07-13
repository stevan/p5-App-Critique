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

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my $root = $opt->root
        ? Path::Tiny::path( $opt->root )
        : $session->git_work_tree;

    my $filter;
    if ( my $f = $opt->filter ) {
        $filter = file_filter($opt,'file_filter_regex');
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

    foreach my $file ( @all ) {
        info(
            'Including %s',
            Path::Tiny::path( $file )->relative( $session->git_work_tree )
        );
    }

    if ( $opt->dry_run ) {
        info('[dry run] %d files found, 0 files added.', $num_files);
    }
    else {
        $session->set_tracked_files( @all );
        info('Sucessfully added %d files.', $num_files);

        $self->cautiously_store_session( $session, $opt, $args );
        info('Session file stored successfully (%s).', $session->session_file_path);
    }
}


my %SKIP = map { ($_ => 1) } qw[  CVS RCS .svn _darcs {arch} .bzr .cdv .git .hg .pc _build blib local ];

sub traverse_filesystem {
    my ($path, $filter, $v) = @_;

    if ( $path->is_file ) {
        return unless is_perl_file( $path );
        return if defined $filter && $filter->( $path );
        $v->( $path );
    }
    elsif ( -l $path ) { # Path::Tiny does not have a test for symlinks
        ;
    }
    else {
        my @children = $path->children( qr/^[^.]/ );
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
