package App::Critique::Session::File;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();
use Carp         ();

use Path::Tiny   ();

sub new {
    my ($class, %args) = @_;

    my $path = $args{path};

    Carp::confess('You must supply a `path` argument')
        unless defined $path;

    $path = Path::Tiny::path( $path )
        unless Scalar::Util::blessed( $path )
            && $path->isa('Path::Tiny');

    return bless {
        path => $path,
        meta => $args{meta} || {},
    } => $class;
}

# accessors

sub path { $_[0]->{path} }
sub meta { $_[0]->{meta} }

sub remember {
    my ($self, $key, $value) = @_;
    $self->{meta}->{ $key } = $value;
    return;
}

sub recall {
    my ($self, $key) = @_;
    return $self->{meta}->{ $key };
}

sub forget {
    my ($self, $key) = @_;
    return delete $self->{meta}->{ $key };
}

sub forget_all {
    my ($self) = @_;
    $self->{meta} = {}
}

# ...

sub relative_path {
    my ($self, $path) = @_;
    return $self->{path}->relative( $path );
}

# ...

sub pack {
    my ($self) = @_;
    return {
        path => $self->{path}->stringify,
        meta => $self->{meta},
    };
}

sub unpack {
    my ($class, $data) = @_;
    return $class->new( %$data );
}

# Filename we're going to be using to 'git add' the fixed file
sub filename_for_git_add {
    my ( $self, $session, $violation ) = @_;

 # Previous implementation used  the path from $violation
 # For perl5 file type, it's the same, and for cases when they are not the same,
 # it should be a separate FileType module
    Path::Tiny::path( $self->path )->relative( $session->git_work_tree_root );
}

# Filename we're going to be using to run editor on in case where auto rewriting
# failed or manual edit requested.
#
# Note that by default this is the same as filename_for_git_add, but other (not necessarily included
# in this distribution) file type modiles need it to implement a workflow like this:
#
# - Transform original tracked file into something critiqeable
# - Run critique on it and make changes
# - Somehow propagate these changes back into git-tracked file
#
sub filename_for_edit {
    my ( $self, $session, $violation ) = @_;
    Path::Tiny::path( $self->path )->relative( $session->git_work_tree_root );
}

sub match_filename {
    die "Abstract class called, implementation is in a FileType module!";
}

sub save_ppi {
    die "Abstract class called, implementation is in a FileType module!";
}

sub critique {
    die "Abstract class called, implementation is in a FileType module!";

}

sub after_manual_edit {
    my ( $self, $session, $violation ) = @_;

    # Hook for doing stuff after manual edit is finished
}

1;

__END__

# ABSTRACT: Information about file processed by App::Critique

=pod

=head1 DESCRIPTION

This is the base class for L<App::Critique::Session::FileType::*>
classes.

=cut
