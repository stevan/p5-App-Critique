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

sub handle_session_file_exception {
    my ($self, $operation, $session_file_path, $e, $debug) = @_;
    if ( $debug ) {
        chomp $e;
        runtime_error("Unable to %s session file (%s), because:\n  %s", $operation, $session_file_path, $e);
    }
    else {
        runtime_error('Unable to %s session file (%s), run with --debug|d for more information', $operation, $session_file_path);
    }
}

1;

__END__

=pod

=cut

