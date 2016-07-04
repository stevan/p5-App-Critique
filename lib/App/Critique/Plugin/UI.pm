package App::Critique::Plugin::UI;

use strict;
use warnings;

use Term::ReadKey ();

use constant TERM_WIDTH => (Term::ReadKey::GetTerminalSize())[0];
use constant HR_ERROR   => ('== ERROR ', ('=' x (TERM_WIDTH - 9)));
use constant HR_DARK    => ('=' x TERM_WIDTH);
use constant HR_LIGHT   => ('-' x TERM_WIDTH);

use App::Critique -ignore;

use App::Cmd::Setup -plugin => {
    exports => [qw[
        TERM_WIDTH
        HR_ERROR
        HR_DARK
        HR_LIGHT

        output
        warning
        runtime_error
        handle_session_file_exception
    ]]
};

sub output {
    my ($plugin, $cmd, $msg, @args) = @_;
    print((sprintf $msg, @args), "\n");
}

sub warning {
    my ($plugin, $cmd, $msg, @args) = @_;
    warn((sprintf $msg, @args), "\n");
}

sub runtime_error {
    my ($plugin, $cmd, $msg, @args) = @_;
    die HR_ERROR, "\n", (sprintf $msg, @args), "\n", HR_DARK, "\n";
}

sub handle_session_file_exception {
    my ($plugin, $cmd, $operation, $session_file_path, $e, $debug) = @_;
    if ( $debug ) {
        chomp $e;
        runtime_error($plugin, $cmd, "Unable to %s session file (%s), because:\n  %s", $operation, $session_file_path, $e);
    }
    else {
        runtime_error($plugin, $cmd, 'Unable to %s session file (%s), run with --debug|d for more information', $operation, $session_file_path);
    }
}

1;

__END__

=pod

=cut
