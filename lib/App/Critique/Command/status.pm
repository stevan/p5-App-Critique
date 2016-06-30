package App::Critique::Command::status;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = App::Critique::Session->locate_session(
        sub {
            my ($session_file, $e) = @_;
            return unless $opt->verbose;
            $self->warning(
                "Unable to load session file (%s) because:\n    %s",
                $session_file // '???',
                $e,
            );
        }
    );

    if ( $session ) {

        my @tracked_files = sort { $a->path cmp $b->path } $session->tracked_files;
        my ($num_files, $num_reviewed, $num_skipped, $num_edited, $num_commited) = (0,0,0,0,0);
        foreach my $file ( @tracked_files ) {
            $num_files++;
            $num_reviewed++ if $file->reviewed;
            $num_skipped++  if $file->skipped;
            $num_edited++   if $file->edited;
            $num_commited++ if $file->commited;
        }

        if ( $opt->verbose ) {
            $self->output($self->HR_DARK);
            $self->output('CONFIG:');
            $self->output($self->HR_LIGHT);
            $self->output('  --perl-critic-profile : %s', $session->perl_critic_profile // '');
            $self->output('  --perl-critic-theme   : %s', $session->perl_critic_theme   // '');
            $self->output('  --perl-critic-policy  : %s', $session->perl_critic_policy  // '');
            $self->output('  --git-work-tree       : %s', $session->git_work_tree       // '');
            $self->output('  --git-branch          : %s', $session->git_branch          // '');
            $self->output($self->HR_DARK);
            $self->output('FILES: <legend: [r|s|e|c] path>');
            $self->output($self->HR_LIGHT);
            foreach my $file ( @tracked_files ) {
                $self->output('[%s|%s|%s|%s] %s',
                    ($file->reviewed ? 'r' : '-'),
                    ($file->skipped  ? 's' : '-'),
                    ($file->edited   ? 'e' : '-'),
                    ($file->commited ? 'c' : '-'),
                    $file->relative_path( $session->git_work_tree ),
                );
            }
        }

        $self->output($self->HR_DARK);
        $self->output('  TOTAL      : %d files', $num_files );
        $self->output('  (r)eviwed  : %d', $num_reviewed );
        $self->output('  (s)kipped  : %d', $num_skipped );
        $self->output('  (e)dited   : %d', $num_edited );
        $self->output('  (c)ommited : %d', $num_commited );
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
