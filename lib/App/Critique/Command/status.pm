package App::Critique::Command::status;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = App::Critique::Session->locate_session(
        sub { $self->handle_session_file_exception('load', @_, $opt->debug) }
    );

    if ( $session ) {

        my @tracked_files = sort { $a->path cmp $b->path } $session->tracked_files;
        my $num_files     = scalar @tracked_files;

        if ( $opt->verbose ) {
            $self->output($self->HR_DARK);
            $self->output('CONFIG:');
            $self->output($self->HR_LIGHT);
            $self->output('  perl_critic_profile : %s', $session->perl_critic_profile // 'auto');
            $self->output('  perl_critic_theme   : %s', $session->perl_critic_theme   // 'auto');
            $self->output('  perl_critic_policy  : %s', $session->perl_critic_policy  // 'auto');
            $self->output('  git_work_tree       : %s', $session->git_work_tree       // 'auto');
            $self->output('  git_branch          : %s', $session->git_branch          // 'auto');
            $self->output($self->HR_DARK);
            $self->output('FILES: <legend: [??] path>');
            $self->output($self->HR_LIGHT);
            foreach my $file ( @tracked_files ) {
                $self->output('[??] %s',
                    $file->relative_path( $session->git_work_tree ),
                );
            }
        }

        $self->output($self->HR_DARK);
        $self->output('TOTAL: %d files', $num_files );
        $self->output($self->HR_LIGHT);
        $self->output('PATH: (%s)', $session->session_file_path);
        $self->output($self->HR_DARK);
    }
    else {
        if ( $opt->verbose ) {
            $self->warning(
                'Unable to locate session file, looking for (%s)',
                App::Critique::Session->locate_session_file // 'undef'
            );
        }
        $self->runtime_error('No session file found, perhaps you forgot to call `init`.');
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

=item has the file been criqued already?

=item did we perform an edit of the file?

=item have any changes been commited?

=back

=cut
