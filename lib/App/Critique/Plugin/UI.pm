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
        HR_WARNING
        HR_DARK
        HR_LIGHT

        info
        warning
        error
    ]]
};

sub info {
    my ($plugin, $cmd, $msg, @args) = @_;
    print((sprintf $msg, @args), "\n");
}

sub warning {
    my ($plugin, $cmd, $msg, @args) = @_;

    # NOTE:
    # I had a timestamp here, but it didn't
    # really help any with the readability,
    # so I took it out, just in case I want
    # it back. I am leaving it here so I
    # don't need to work this out again.
    # - SL
    # my @time = (localtime)[ 2, 1, 0, 4, 3, 5 ];
    # $time[-1] += 1900;
    # sprintf '%02d:%02d:%02d-%02d/%02d/%d', @time;

    warn('[WARN] ',(sprintf $msg, @args),"\n");
}

sub error {
    my ($plugin, $cmd, $msg, @args) = @_;
    die HR_ERROR,"\n",(sprintf $msg, @args),"\n",HR_DARK,"\n";
}

1;

__END__

=pod

=cut
