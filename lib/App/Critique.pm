package App::Critique;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our %CONFIG; 

BEGIN {
    $App::Critique::CONFIG{'COLOR'}   = $ENV{'CRITIQUE_COLOR'};
    $App::Critique::CONFIG{'DEBUG'}   = $ENV{'CRITIQUE_DEBUG'};
    $App::Critique::CONFIG{'VERBOSE'} = $ENV{'CRITIQUE_VERBOSE'};
    $App::Critique::CONFIG{'EDITOR'}  = $ENV{'CRITIQUE_EDITOR'};
}

use App::Cmd::Setup -app => {
    plugins => [
        'Prompt',
        '=App::Critique::Plugin::UI',
        '=App::Critique::Plugin::FileFilter'
    ]
};

1;

__END__

=pod

=cut
