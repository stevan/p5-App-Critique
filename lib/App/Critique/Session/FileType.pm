package App::Critique::Session::FileType;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use Module::Runtime ();
use Carp            ();

my @FILE_TYPES_IN_USE;

sub set_file_types {
    my ( $class, @file_types ) = @_;

    for (@file_types) {
        my $ft_class = __PACKAGE__ .'::'. $_;
        Module::Runtime::use_module( $ft_class );
        push @FILE_TYPES_IN_USE, $ft_class;
    }
    return;
}

sub matching_filetype {
    my ( $class, $fname ) = @_;
    Carp::confess "File types in use are not defined yet" if !@FILE_TYPES_IN_USE;
    foreach my $ft (@FILE_TYPES_IN_USE) {
        $ft->match_filename($fname) and return $ft;
    }
    return;
}

# Return 'perl5' for App::Critique::Session::FileType::perl5
sub shortname {
    my ($class, $fully_qualified_class) = @_;
    if ( $fully_qualified_class =~ /(?<=::)(\w+)$/ ) {
        return $1;
    }
}

1;
