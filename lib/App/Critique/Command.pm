package App::Critique::Command;

use strict;
use warnings;

use App::Cmd::Setup -command;

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'verbose|v', 'display additional information', { default => $ENV{CRITIQUE_VERBOSE}                     } ],
        [ 'debug|d',   'display debugging information',  { default => $ENV{CRITIQUE_DEBUG}, implies => 'verbose' } ],
    );
}

1;

__END__

=pod

=cut

