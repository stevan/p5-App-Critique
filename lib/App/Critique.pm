package App::Critique;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use File::HomeDir ();
use JSON::MaybeXS ();

use App::Critique::Utils ();

# load our CONFIG first, ...

our %CONFIG;
BEGIN {
    $CONFIG{'HOME'}      = $ENV{'CRITIQUE_HOME'}      || File::HomeDir->my_home;
    $CONFIG{'DATA_DIR'}  = $ENV{'CRITIQUE_DATA_DIR'}  || '.critique';
    $CONFIG{'DATA_FILE'} = $ENV{'CRITIQUE_DATA_FILE'} || 'session.json';
    $CONFIG{'COLOR'}     = $ENV{'CRITIQUE_COLOR'}     // 1;
    $CONFIG{'DEBUG'}     = $ENV{'CRITIQUE_DEBUG'}     // 0;
    $CONFIG{'VERBOSE'}   = $ENV{'CRITIQUE_VERBOSE'}   // 0;

    # try and deterimine if we have an editor ...
    $CONFIG{'EDITOR'} = $ENV{'CRITIQUE_EDITOR'} || $ENV{'EDITOR'} || $ENV{'VISUAL'};

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

    $ENV{'ANSI_COLORS_DISABLED'} = ! $CONFIG{'COLOR'};
}

# ... then gloablly used stuff, ....

our $JSON = JSON::MaybeXS->new->utf8->pretty->canonical;

# ... then load the app and plugins

use App::Cmd::Setup -app => {
    plugins => [
        'Prompt',
        '=App::Critique::Plugin::UI',
    ]
};

# UGLY HACK:
# We only override `run` so that we
# can check the EDITOR settings at
# a sensible time, but this is kinda
# ugly, sorry.
# - SL
sub run {
    my ($self, @args) = @_;

    # before we run, make sure the editor is good ...
    die '## !! IMPORTANT !!'
            ."\n"
        . '## The editor ('.($CONFIG{'EDITOR'} // 'undef').') found in the %ENV is not supported.'
            ."\n"
        . '## Supported editors:'
            ."\n"
            .'##   - '.(join ', ' => App::Critique::Utils::supported_editors())
            ."\n"
        .'## Supported editor aliases:'
            ."\n"
            .'##   - '.(join ', ' => App::Critique::Utils::supported_editor_aliases())
            ."\n"
        .'## Please choose an editor and set the $ENV{CRITIQUE_EDITOR} variable.'
            ."\n"
        .'## (NOTE: Patches welcome for adding support for additional editors)'
            ."\n\n"
        unless App::Critique::Utils::can_support_editor( $CONFIG{'EDITOR'} );

    return $self->SUPER::run( @args );
}

1;

__END__

# ABSTRACT: An incremental refactoring tool for Perl powered by Perl::Critic

=pod

=head1 DESCRIPTION

This tool is specifically designed to find syntactic patterns in Perl source
code and allow you to review, refactor and commit your changes in one smooth
workflow.

The idea behind L<App::Critique> is based on two assumptions.

The first is that refactoring often involves a lot of repetitive and easily
automated actions, and this tool aims to make this workflow as smooth as
possible.

The second is that many people, working on small incremental code improvements,
in individual easily revertable commits, can have a huge effect on a codebase,
which is exactly what this tool aims to do.

The quickest way to start is to read the tutorial either by viewing the
documentation for L<App::Critique::Command::tutorial> or by installing the
app and running the following

  > critique tutorial

=cut
