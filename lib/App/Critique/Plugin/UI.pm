package App::Critique::Plugin::UI;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Term::ReadKey ();
use Term::ReadKey  ();
use Number::Format ();

use constant TERM_WIDTH => (Term::ReadKey::GetTerminalSize())[0] // 80;
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

        info
        warning
        error
        
        format_number
        format_bytes
    ]]
};

sub info    { my ($plugin, $cmd, @args) = @_;    _info( @args ) }
sub warning { my ($plugin, $cmd, @args) = @_; _warning( @args ) }
sub error   { my ($plugin, $cmd, @args) = @_;   _error( @args ) }

sub format_number {
    my ($plugin, $cmd, @args) = @_;
    Number::Format::format_number( @args );
}

sub format_bytes {
    my ($plugin, $cmd, @args) = @_;
    Number::Format::format_bytes( @args );
}

# the real stuff

sub _info {
    my ($msg, @args) = @_;
    print((sprintf $msg, @args), "\n");
}

sub _warning {
    my ($msg, @args) = @_;

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

    warn((sprintf $msg, @args),"\n");
}

sub _error {
    my ($msg, @args) = @_;
    die(HR_ERROR,"\n",(sprintf $msg, @args),"\n",HR_DARK,"\n");
}

1;

__END__

=pod

=cut
