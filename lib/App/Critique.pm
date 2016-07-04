package App::Critique;

use strict;
use warnings;

use App::Cmd::Setup -app => {
    plugins => [
        'Prompt',
        '=App::Critique::Plugin::UI'
    ]
};

1;

__END__

=pod

=cut
