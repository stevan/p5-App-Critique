package App::Critique::Command::remove;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    [ 'verbose|v', 'display debugging information', { default => $ENV{CRITIQUE_VERBOSE} } ]
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session_file = App::Critique::Session->locate_session_file;

    if (-e $session_file) {
        $self->output('Attempting to remove session file ...');
        my $ok = unlink $session_file;
        if ( $ok ) {
            $self->output('Successfully removed session file (%s).', $session_file);
        }
        else {
            if ( $opt->verbose ) {
                $self->warning(
                    'Could not remove session file (%s) because: %s',
                    $session_file,
                    $!
                );
            }
            $self->runtime_error('Unable to remove session file.');
        }
    }
    else {
        if ( $opt->verbose ) {
            $self->warning(
                'Unable to locate session file, looking for (%s)',
                $session_file // 'undef'
            );
        }
        $self->runtime_error('No session file found.');
    }
}

1;

__END__

# ABSTRACT: Display status of the current critique session.

=pod

=head1 NAME

App::Critique::Command::status - Critique all the files.

=head1 DESCRIPTION

This command will display information about the current critique session.
Among other things, this will include information about each of the files,
such as:

=over 4

=item has the file been reviewed for violations?

=item did we perform an edit of the file?

=item have any changes been commited?

=back

=cut
