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


1;

__END__

# ABSTRACT: Information about file processed by App::Critique

=pod

=head1 DESCRIPTION

This class holds information about files that have been processed
by L<App::Critique> and contains no real user serviceable parts.

=cut
