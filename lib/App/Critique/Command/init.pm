package App::Critique::Command::init;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'perl-critic-profile=s', 'path to a Perl::Critic profile to use (default let Perl::Critic decide)' ],
        [ 'perl-critic-theme=s',   'Perl::Critic theme expression to use' ],
        [ 'perl-critic-policy=s',  'singular Perl::Critic policy to use (overrides -theme and -policy)' ],
        [],
        [ 'force',                 'force overwriting of existing session file' ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if ( my $profile = $opt->perl_critic_profile ) {
        (-f $profile)
            || $self->usage_error('Unable to locate perl-critic-profile (' . $profile . ')');
    }

}

sub execute {
    my ($self, $opt, $args) = @_;

    if ( $opt->verbose ) {
        output(HR_LIGHT);
        output('Attempting to initialize session file using the following options:');
        output(HR_LIGHT);
        output('  --perl-critic-profile = (%s)', $opt->perl_critic_profile // 'auto');
        output('  --perl-critic-theme   = (%s)', $opt->perl_critic_theme   // 'auto');
        output('  --perl-critic-policy  = (%s)', $opt->perl_critic_policy  // 'auto');
    }
    else {
        output('Attempting to initialize session file ...');
    }

    my $session = App::Critique::Session->new(
        perl_critic_profile => $opt->perl_critic_profile,
        perl_critic_theme   => $opt->perl_critic_theme,
        perl_critic_policy  => $opt->perl_critic_policy,
    );

    if ( $opt->verbose ) {
        output(HR_LIGHT);
        output('Successuflly created session with the following configuration:');
        output(HR_LIGHT);
        output('  perl_critic_profile = (%s)', $session->perl_critic_profile // 'auto');
        output('  perl_critic_theme   = (%s)', $session->perl_critic_theme   // 'auto');
        output('  perl_critic_policy  = (%s)', $session->perl_critic_policy  // 'auto');
        output('  git_work_tree       = (%s)', $session->git_work_tree       // 'auto');
        output('  git_branch          = (%s)', $session->git_branch          // 'auto');
        output(HR_LIGHT);
    }

    if ( $session->session_file_exists ) {
        my $session_file_path = $session->session_file_path;
        if ( $opt->force ) {
            output('!! Overwriting session file (%s) with --force option.', $session_file_path);
        }
        else {
            runtime_error(
                'Unable to overwrite session file (%s) without --force option.',
                $session_file_path
            );
        }
    }

    eval {
        $session->store;
        1;
    } or handle_session_file_exception(
        store => ($session->session_file_path, "$@", $opt->debug)
    );

    output('Session file (%s) initialized successfully.', $session->session_file_path);
}

1;

__END__

# ABSTRACT: Initialize critique session file

=pod

=head1 NAME

App::Critique::Command::init - Initialize critique session file

=head1 DESCRIPTION

This command will create a critique session file in your F<~/.critique>
directory (including creating the F<~/.critique> directory if needed).
This file will be used to store information about the critque session,
such as the set of files you wish to critique and your progress in
processing the set.

The specific file path for the critique session will be based on the
information provided through the command line options, and will look
something like this:

  ~/.critique/<git-repo>/<git-branch>/session.json

The value of C<git-repo> will be surmised from the C<git-work-tree>
which itself defaults to finding the root of the C<git> working directory
via your current working directory.

The value of C<git-branch> comes directly from the command line option,
or will default itself to the currently active C<git> branch.

You must also supply L<Perl::Critic> informaton must be specified, either
as a L<Perl::Critic> profile config (ex: F<perlcriticrc>) with additional
L<Perl::Critic> 'theme' expression added. Alternatively you can just
specify a single L<Perl::Critic::Policy> to use during the critique
session.

=cut
