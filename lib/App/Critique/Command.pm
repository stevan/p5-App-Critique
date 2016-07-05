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

sub cautiously_load_session {
    my ($self, $opt, $args) = @_;

    if ( my $session_file_path = App::Critique::Session->locate_session_file ) {

        my $session;
        eval {
            $session = App::Critique::Session->load( $session_file_path );
            1;
        } or do {
            my $e = "$@";
            chomp $e;
            if ( $opt->debug ) {
                error("Unable to load session file (%s), because:\n  %s", $session_file_path, $e);
            }
            else {
                error('Unable to load session file (%s), run with --debug|d for more information', $session_file_path);
            }
        };

        return $session;
    }

    error('No session file found, perhaps you forgot to call `init`.');
}

sub cautiously_store_session {
    my ($self, $session, $opt, $args) = @_;

    my $session_file_path = $session->session_file_path;

    eval {
        $session->store;
        1;
    } or do {
        my $e = "$@";
        chomp $e;
        if ( $opt->debug ) {
            error("Unable to store session file (%s), because:\n  %s", $session_file_path, $e);
        }
        else {
            error('Unable to store session file (%s), run with --debug|d for more information', $session_file_path);
        }
    };

    return $session_file_path;
}

1;

__END__

=pod

=cut

