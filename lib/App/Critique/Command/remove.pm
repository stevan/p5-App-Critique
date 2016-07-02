package App::Critique::Command::remove;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'dry-run', 'display list of files to be removed, but do not remove them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session_file = App::Critique::Session->locate_session_file;

    if (-e $session_file) {
        $self->output('Attempting to remove session file ...');

        if ( $opt->dry_run ) {
            $self->output('[dry-run] Found session file (%s), not removing.', $session_file);
        }
        else {
            if ( $session_file->remove ) {
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

            $self->output('Attempting to clean up session directory ...');

            my $branch = $session_file->parent;
            if ( my @children = $branch->children ) {
                $self->output('Branch directory (%s) is not empty, it will not be removed', $branch);
                if ( $opt->verbose ) {
                    $self->output('Branch directory (%s) contains:', $branch);
                    $self->output('  %s', $_) foreach @children;
                }
            }
            else {
                $self->output('Attempting to remove empty branch directory ...');
                if ( $branch->rmtree ) {
                    $self->output('Successfully removed empty branch directory (%s).', $branch);
                }
                else {
                    if ( $opt->verbose ) {
                        $self->warning(
                            'Could not remove empty branch directory (%s) because: %s',
                            $branch,
                            $!
                        );
                    }
                    $self->runtime_error('Unable to remove empty branch directory file.');
                }
            }

            my $repo = $branch->parent;
            if ( my @children = $repo->children ) {
                $self->output('Branch directory (%s) is not empty, it will not be removed', $repo);
                if ( $opt->verbose ) {
                    $self->output('Repo directory (%s) contains:', $repo);
                    $self->output('  %s', $_) foreach @children;
                }
            }
            else {
                $self->output('Attempting to remove empty repo directory ...');
                if ( $repo->rmtree ) {
                    $self->output('Successfully removed empty repo directory (%s).', $repo);
                }
                else {
                    if ( $opt->verbose ) {
                        $self->warning(
                            'Could not remove empty repo directory (%s) because: %s',
                            $branch,
                            $!
                        );
                    }
                    $self->runtime_error('Unable to remove empty repo directory file.');
                }
            }
        }

    }
    else {
        if ( $opt->verbose ) {
            $self->warning(
                'Unable to locate session file, looking for (%s)',
                $session_file // 'undef'
            );
        }
        $self->runtime_error('No session file found, nothing removed.');
    }
}

1;

__END__

# ABSTRACT: Display status of the current critique session.

=pod

=head1 NAME

App::Critique::Command::status - Critique all the files.

=head1 DESCRIPTION

This command will remove the current session file, afterwhich
it will attempt to delete the branch (../) directory and the
repository (../../) directory if they are empty.

=cut
