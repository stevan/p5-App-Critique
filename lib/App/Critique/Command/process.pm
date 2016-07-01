package App::Critique::Command::process;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'reset|r', 'resets the file index to 0', { default => 0 } ],
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

        $session->reset_file_idx if $opt->reset;

        my @tracked_files = $session->tracked_files;

        if ( $session->current_file_idx == scalar @tracked_files ) {
            $self->output($self->HR_DARK);
            $self->output('All files have already been processed.');
            $self->output($self->HR_LIGHT);
            $self->output('- run `critique status` to see more information');
            $self->output('- run `critique process --reset` to review all files again');
            $self->output($self->HR_DARK);
        }
        else {

        MAIN:
            while (1) {

                $self->output($self->HR_LIGHT);

                my $idx  = $session->current_file_idx;
                my $file = $tracked_files[ $idx ];
                my $path = $file->relative_path( $session->git_work_tree );

                if ( defined $file->recall('violations') ) {
                    my $should_review_again = prompt_yn(
                        (sprintf 'File (%s) already checked, found %d violations, would you like to critique the file again?', $path, $file->recall('violations')),
                        { default => 'y' }
                    );

                    $self->output($self->HR_LIGHT);
                    if ( $should_review_again ) {
                        $file->forget('violations');
                    }
                    else {
                        next MAIN;
                    }
                }

                $self->output('Running Perl::Critic against (%s)', $path);
                $self->output($self->HR_LIGHT);

                my @violations = $self->discover_violations( $session, $file, $opt );

                $file->remember('violations' => scalar @violations);

                if ( @violations == 0 ) {
                    $self->output('No violations found, proceeding to next file.');
                    $self->output($self->HR_LIGHT);
                    next MAIN;
                }
                else {
                    my $should_review = prompt_yn(
                        (sprintf 'Found %d violations, would you like to review them?', (scalar @violations)),
                        { default => 'y' }
                    );

                    if ( $should_review ) {

                        my ($reviewed, $edited, $fixed) = (0, 0, 0);

                        foreach my $violation ( @violations ) {

                            $self->display_violation( $session, $file, $violation, $opt );
                            $reviewed++;

                            my $should_edit = prompt_yn(
                                'Would you like to fix this violation?',
                                { default => 'y' }
                            );

                            if ( $should_edit ) {
                                $edited++;
                                EDIT:
                                    my $cmd = sprintf $ENV{CRITIQUE_EDITOR} => ($violation->filename, $violation->line_number, $violation->column_number);
                                    system $cmd;
                                    prompt_yn('Are you finished editing?', { default => 'y' })
                                        || goto EDIT;
                                $fixed++;
                            }
                        }

                        $file->remember('reviewed', $reviewed);
                        $file->remember('edited',   $edited);
                        $file->remember('fixed',    $fixed);
                    }
                }

                $self->output($self->HR_LIGHT);
            } continue {

                if ( ($session->current_file_idx + 1) == scalar @tracked_files ) {
                    $self->output('Processing complete, run `status` to see results.');
                    $session->inc_file_idx;
                    $session->store;
                    last MAIN;
                }

                my $where_to = prompt_str(
                    '>> (n)ext (p)rev (r)efresh (s)top',
                    {
                        valid   => sub { $_[0] =~ m/[nprs]{1}/ },
                        default => 'n',
                    }
                );

                if ( $where_to eq 'n' ) {
                    $session->inc_file_idx;
                    $session->store;
                }
                elsif ( $where_to eq 'p' ) {
                    $session->dec_file_idx;
                    $session->store;
                }
                elsif ( $where_to eq 'r' ) {
                    redo MAIN;
                }
                elsif ( $where_to eq 's' ) {
                    $session->inc_file_idx;
                    $session->store;
                    last MAIN;
                }

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

sub discover_violations {
    my ($self, $session, $file, $opt) = @_;

    my @violations = $session->perl_critic->critique( $file->path->stringify );

    return @violations;
}


sub display_violation {
    my ($self, $session, $file, $violation, $opt) = @_;
    $self->output($self->HR_DARK);
    $self->output('Violation: %s', $violation->description);
    $self->output($self->HR_DARK);
    $self->output('%s', $violation->explanation);
    if ( $opt->verbose ) {
        $self->output($self->HR_LIGHT);
        $self->output('%s', $violation->diagnostics);
    }
    $self->output($self->HR_LIGHT);
    $self->output('  policy   : %s'           => $violation->policy);
    $self->output('  severity : %d'           => $violation->severity);
    $self->output('  location : %s @ <%d:%d>' => Path::Class::File->new( $violation->filename )->relative( $session->git_work_tree ),
                                                 $violation->line_number,
                                                 $violation->column_number);
    $self->output($self->HR_LIGHT);
    $self->output('%s', $violation->source);
    $self->output($self->HR_LIGHT);
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
