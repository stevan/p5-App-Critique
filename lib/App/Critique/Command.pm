package App::Critique::Command;

use strict;
use warnings;

use Term::ReadKey ();

use constant TERM_WIDTH => (Term::ReadKey::GetTerminalSize())[0];
use constant HR_ERROR   => ('== ERROR ', ('=' x (TERM_WIDTH - 9)));
use constant HR_DARK    => ('=' x TERM_WIDTH);
use constant HR_LIGHT   => ('-' x TERM_WIDTH);

use App::Cmd::Setup -command;

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'verbose|v', 'display additional information', { default => $ENV{CRITIQUE_VERBOSE}                     } ],
        [ 'debug|d',   'display debugging information',  { default => $ENV{CRITIQUE_DEBUG}, implies => 'verbose' } ],
    );
}

sub output {
    my ($self, $msg, @args) = @_;
    print((sprintf $msg, @args), "\n");
}

sub warning {
    my ($self, $msg, @args) = @_;
    warn((sprintf $msg, @args), "\n");
}

sub runtime_error {
    my ($self, $msg, @args) = @_;
    die HR_ERROR, "\n", (sprintf $msg, @args), "\n", HR_DARK, "\n";
}

1;

__END__

=pod

=cut

