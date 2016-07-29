package App::Critique;

use strict;
use warnings;

use File::HomeDir ();
use JSON::XS      ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

# load our CONFIG first, ...

our %CONFIG;
BEGIN {
    $CONFIG{'HOME'}    = $ENV{'CRITIQUE_HOME'}    || File::HomeDir->my_home;
    $CONFIG{'COLOR'}   = $ENV{'CRITIQUE_COLOR'}   || 0;
    $CONFIG{'DEBUG'}   = $ENV{'CRITIQUE_DEBUG'}   || 0;
    $CONFIG{'VERBOSE'} = $ENV{'CRITIQUE_VERBOSE'} || 0;
    $CONFIG{'EDITOR'}  = $ENV{'CRITIQUE_EDITOR'}  || $ENV{'EDITOR'} || $ENV{'VISUAL'};

    # okay, we give you sensible Perl & Git defaults
    $CONFIG{'IGNORE'} = {
        '.git'   => 1,
        'blib'   => 1,
        'local'  => 1,
        '_build' => 1,
    };

    # then we add in any of yours
    if ( my $ignore = $ENV{'CRITIQUE_IGNORE'} ) {
        $CONFIG{'IGNORE'}->{ $_ } = 1
            foreach split /\:/ => $ignore;
    }
}

# ... then gloablly used stuff, ....

our $JSON = JSON::XS->new->utf8->pretty->canonical;

# ... then load the app and plugins

use App::Cmd::Setup -app => {
    plugins => [
        'Prompt',
        '=App::Critique::Plugin::UI',
    ]
};

1;

__END__

=pod

=cut
