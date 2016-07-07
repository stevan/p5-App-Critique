package App::Critique::Command::process;

use strict;
use warnings;

use Path::Tiny ();

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'reset|r', 'resets the file index to 0', { default => 0 } ],
        [ 'prev|p',  'moves the file index back by one', { default => 0 } ],
        [],
        $class->SUPER::opt_spec
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    $session->reset_file_idx if $opt->reset;
    $session->dec_file_idx   if $opt->prev;

    my @tracked_files = $session->tracked_files;

    if ( $session->current_file_idx == scalar @tracked_files ) {
        info(HR_DARK);
        info('All files have already been processed.');
        info(HR_LIGHT);
        info('- run `critique status` to see more information');
        info('- run `critique process --reset` to review all files again');
        info(HR_DARK);
        return;
    }

MAIN:
    while (1) {

        info(HR_LIGHT);

        my $idx  = $session->current_file_idx;
        my $file = $tracked_files[ $idx ];
        my $path = $file->relative_path( $session->git_work_tree );

        if ( defined $file->recall('violations') ) {
            my $should_review_again = prompt_yn(
                (sprintf 'File (%s) already checked, found %d violations, would you like to critique the file again?', $path, $file->recall('violations')),
                { default => 'y' }
            );

            info(HR_LIGHT);
            if ( $should_review_again ) {
                $file->forget('violations');
            }
            else {
                next MAIN;
            }
        }

        info('Running Perl::Critic against (%s)', $path);
        info(HR_LIGHT);

        my @violations = $self->discover_violations( $session, $file, $opt );

        $file->remember('violations' => scalar @violations);

        if ( @violations == 0 ) {
            info('No violations found, proceeding to next file.');
            info(HR_LIGHT);
            next MAIN;
        }
        else {
            my $should_review = prompt_yn(
                (sprintf 'Found %d violations, would you like to review them?', (scalar @violations)),
                { default => 'y' }
            );

            if ( $should_review ) {

                my ($reviewed, $edited) = (0, 0);

                $self->begin_editing_session( $file );

                foreach my $violation ( @violations ) {

                    $self->display_violation( $session, $file, $violation, $opt );
                    $reviewed++;

                    my $should_edit = prompt_yn(
                        'Would you like to fix this violation?',
                        { default => 'y' }
                    );

                    if ( $should_edit ) {
                        $edited++;
                        $self->edit_violation( $session, $file, $violation );
                    }
                }

                $self->end_editing_session( $file );

                $file->remember('reviewed', $reviewed);
                $file->remember('edited',   $edited);
            }
        }

        info(HR_LIGHT);
    } continue {

        if ( ($session->current_file_idx + 1) == scalar @tracked_files ) {
            info('Processing complete, run `status` to see results.');
            $session->inc_file_idx;
            $self->cautiously_store_session( $session, $opt, $args );
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
            $self->cautiously_store_session( $session, $opt, $args );
        }
        elsif ( $where_to eq 'p' ) {
            $session->dec_file_idx;
            $self->cautiously_store_session( $session, $opt, $args );
        }
        elsif ( $where_to eq 'r' ) {
            redo MAIN;
        }
        elsif ( $where_to eq 's' ) {
            $session->inc_file_idx;
            $self->cautiously_store_session( $session, $opt, $args );
            last MAIN;
        }

    }

}

sub discover_violations {
    my ($self, $session, $file, $opt) = @_;

    my @violations = $session->perl_critic->critique( $file->path->stringify );

    return @violations;
}


sub display_violation {
    my ($self, $session, $file, $violation, $opt) = @_;
    info(HR_DARK);
    info('Violation: %s', $violation->description);
    info(HR_DARK);
    info('%s', $violation->explanation);
    if ( $opt->verbose ) {
        info(HR_LIGHT);
        info('%s', $violation->diagnostics);
    }
    info(HR_LIGHT);
    info('  policy   : %s'           => $violation->policy);
    info('  severity : %d'           => $violation->severity);
    info('  location : %s @ <%d:%d>' => (
        Path::Tiny::path( $violation->filename )->relative( $session->git_work_tree ),
         $violation->line_number,
         $violation->column_number
    ));
    info(HR_LIGHT);
    info('%s', $violation->source);
    info(HR_LIGHT);
}


sub begin_editing_session {
    my ($self, $file) = @_;
    $self->{_editor_line_offset} //= {};
    $self->{_editor_line_offset}->{ $file->relative_path } = 0;
}

sub end_editing_session {
    my ($self, $file) = @_;
    delete $self->{_editor_line_offset}->{ $file->relative_path };
}

sub edit_violation {
    my ($self, $session, $file, $violation) = @_;

    my $git      = $session->git_repository;
    my $filename = $violation->filename;

    #warning('!!!! do we have an editor offset (%d) for file (%s)' => $self->{_editor_line_offset}->{ $filename }, $filename);

    #use Data::Dumper;
    #warn Dumper $self->{_editor_line_offset};

    my $cmd_fmt  = $App::Critique::CONFIG{EDITOR};
    my @cmd_args = (
        $filename,
        ($violation->line_number + $self->{_editor_line_offset}->{ $file->relative_path }),
        $violation->column_number
    );

    my $cmd = sprintf $cmd_fmt => @cmd_args;

EDIT:
    system $cmd;

    my @modified = $git->run( status  => '--short' );
    my $did_edit = scalar grep /$filename/, @modified;

    if ( $did_edit ) {
        info(HR_LIGHT);
        info('Changes detected.');
        info(HR_LIGHT);
    CHOOSE:
        my $what_now = prompt_str(
            'What would you like to do? (c)ommit (d)iff (e)dit (s)kip',
            {
                valid   => sub { $_[0] =~ m/[cdes]{1}/ },
                default => 'c',
            }
        );

        if ( $what_now eq 'c' ) {
            info(HR_LIGHT);
            my $policy_name = $violation->policy;
            $policy_name =~ s/^Perl\:\:Critic\:\:Policy\:\://;

            my $commit_msg = prompt_str(
                'Please write a commit message, or choose the default',
                {
                    default => (sprintf "critique(%s) - %s" => $policy_name, $violation->description),
                    output => sub {
                        my ($msg, $default) = @_;
                        my $length = (length $default) + 2;
                        print $msg,"\n+",('-' x $length),"+\n| ",$default," |\n+",('-' x $length),"+\n> ";
                    }
                }
            );

            $commit_msg =~ s/^\s*//g;
            $commit_msg =~ s/\s*$//g;

            my ($changes) = grep /$filename/, $git->run( diff => '--numstat' );
            ($changes)
                || error('Unable to find changes in diff for file (%s)', $file->relative_path);
            my ($inserts, $deletes) = ($changes =~ /^(\d+)\s*(\d+)\s*.*$/);
            $self->{_editor_line_offset}->{ $file->relative_path } += ($inserts + (-$deletes));

            info(HR_DARK);
            info('Adding file (%s) to git', $filename);
            info(HR_LIGHT);
            info('%s', join "\n" => $git->run( add => '-v' => $filename ));
            info(HR_DARK);
            info('Commiting file (%s) to git', $filename);
            info(HR_LIGHT);
            info('%s', join "\n" => $git->run( commit => '-v' => '-m' => $commit_msg));

            $file->remember('commited' => ($file->recall('commited') || 0) + 1);

            return;
        }
        elsif ( $what_now eq 'd' ) {
            info(HR_LIGHT);
            info('%s', join "\n" => $git->run( diff => '-v' ));
            info(HR_LIGHT);
            goto CHOOSE;
        }
        elsif ( $what_now eq 'e' ) {
            goto EDIT;
        }
        elsif ( $what_now eq 'n' ) {
            return;
        }
    }
    else {
        info(HR_LIGHT);
        info('No edits found for file (%s), skipping to next violation or file', $filename);
    }

    return;
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
