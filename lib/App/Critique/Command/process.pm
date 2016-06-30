package App::Critique::Command::process;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        $class->SUPER::opt_spec
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = App::Critique::Session->locate_session(
        sub { $self->handle_session_file_exception('load', @_, $opt->debug) }
    );

    if ( $session ) {

        my @tracked_files = $session->tracked_files;

        $self->output($self->HR_LIGHT);

        while (1) {

            my $idx  = $session->current_file_idx;
            my $file = $tracked_files[ $idx ];
            my $path = $file->relative_path( $session->git_work_tree );

            $self->output('%s', $path);
            $self->output($self->HR_LIGHT);

            my $answer = prompt_str(
                '>> (r)eview (e)dit (d)iff (c)ommit (n)ext (q)uit',
                {
                    valid   => sub { $_[0] =~ /[redcnq]{1}/ },
                    default => 'n',
                }
            );
            $self->output($self->HR_LIGHT);

            if ( $answer eq 'r' ) {
                $self->output('[reviewing] %s', $path);

            }
            elsif ( $answer eq 'e' ) {
                $self->output('[editing] %s', $path);

            }
            elsif ( $answer eq 'd' ) {
                $self->output('[diffing] %s', $path);
                my $diff = $session->git_repository->run('diff');
                warn $diff;
            }
            elsif ( $answer eq 'c' ) {
                $self->output('[commiting] %s', $path);

            }
            elsif ( $answer eq 'n' ) {
                $self->output('[advancing]');
                $session->inc_file_idx;
            }
            elsif ( $answer eq 'q' ) {
                $self->output('[quitting]');
                last;
            }
        }

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

# ABSTRACT: Critique all the files.

=pod

=head1 NAME

App::Critique::Command::process - Critique all the files.

=head1 DESCRIPTION

This command will start or resume the critique session, allowing you to
step through the files and critique them. This current state of this
processing will be stored in the critique session file and so can be
stopped and resumed at any time.

Note, this is an interactive command, so ...

=cut
