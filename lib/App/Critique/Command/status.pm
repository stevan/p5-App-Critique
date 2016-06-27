package App::Critique::Command::status;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    [ 'verbose|v', 'display debugging information' ]
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    # ...
}

sub execute {
    my ($self, $opt, $args) = @_;

    if ( my $session = eval { App::Critique::Session->locate_session } ) {
        $self->output('CONFIG:');
        $self->output('  --perl-critic-profile : %s', $session->perl_critic_profile // '');
        $self->output('  --perl-critic-theme   : %s', $session->perl_critic_theme   // '');
        $self->output('  --perl-critic-policy  : %s', $session->perl_critic_policy  // '');
        $self->output('  --git-work-tree       : %s', $session->git_work_tree       // '');
        $self->output('  --git-branch          : %s', $session->git_branch          // '');
        $self->output('FILES:');
        $self->output('(legend: e|r|c - path)',
        foreach my $file ( $session->tracked_files ) {
            $self->output('%s|%s|%s - %s',
                $file->{edited}   ? 'e' : '-',
                $file->{reviewed} ? 'r' : '-',
                $file->{commited} ? 'c' : '-',
                $file->{path}
            );
        }

    }
    else {
        if ( $opt->verbose ) {
            $self->warning(
                'Unable to locate session file, looking for (%s)',
                App::Critique::Session->locate_session_file // 'undef'
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

=item has the file been criqued already?

=item did we perform an edit of the file?

=item have any changes been commited?

=back

=cut
