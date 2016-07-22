package App::Critique::Session::File;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();
use Carp         ();

use Path::Tiny   ();

sub new {
    my ($class, %args) = @_;

    my $path = $args{path};

    Carp::confess('You must supply a `path` argument')
        unless defined $path;

    Carp::confess('The `path` argument must be a valid file, not: ' . $path)
        unless -e $path && -f $path;

    $path = Path::Tiny::path( $path )
        unless Scalar::Util::blessed( $path )
            && $path->isa('Path::Tiny');

    return bless {
        path => $path,
        meta => $args{meta} // {},
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

=pod

=cut
