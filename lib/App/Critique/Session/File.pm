package App::Critique::Session::File;

use strict;
use warnings;

use Scalar::Util        ();
use Carp                ();

use File::Spec          ();
use Path::Class         ();

sub new {
    my ($class, %args) = @_;

    my $path = $args{path};

    (defined $path)
        || Carp::confess('You must supply a `path` argument');

    (-e $path && -f $path)
        || Carp::confess('The `path` argument must be a valid file, not: ' . $path);

    $path = Path::Class::File->new( $path )
        unless Scalar::Util::blessed( $path )
            && $path->isa('Path::Class::File');

    return bless {
        path     => $path,
    } => $class;
}

# accessors

sub path { $_[0]->{path} }

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
