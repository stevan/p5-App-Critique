package App::Critique::Command::init;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    [ 'perl-critic-profile=s', 'path to a Perl::Critic profile to use (default let Perl::Critic decide)' ],
    [ 'perl-critic-theme=s',   'Perl::Critic theme expression to use' ],
    [ 'perl-critic-policy=s',  'singular Perl::Critic policy to use (overrides -theme and -policy)' ],

    [ 'git-work-tree=s',       'path to the git working directory (default is current directory)', { default => File::Spec->curdir } ],
    [ 'git-branch=s',          'name of git branch to use for critique', { default => 'master' } ],

    [ 'force',                 'force overwriting of existing session file' ],
    [ 'verbose|v',             'display debugging information' ],
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if ( my $profile = $opt->perl_critic_profile ) {
        (-f $profile)
            || $self->usage_error('Unable to locate perl-critic-profile (' . $profile . ')');
    }

    if ( my $work_tree = $opt->git_work_tree ) {
        (-d $work_tree)
            || $self->usage_error('Unable to locate git-work-tree (' . $work_tree . ')');
    }

}

sub execute {
    my ($self, $opt, $args) = @_;

    if ( $opt->verbose ) {
        $self->output('Initializing session file using the following options:');
        $self->output('  --perl-critic-profile = (%s)', $opt->perl_critic_profile // '');
        $self->output('  --perl-critic-theme   = (%s)', $opt->perl_critic_theme   // '');
        $self->output('  --perl-critic-policy  = (%s)', $opt->perl_critic_policy  // '');
        $self->output('  --git-work-tree       = (%s)', $opt->git_work_tree       // '');
        $self->output('  --git-branch          = (%s)', $opt->git_branch          // '');
    }
    else {
        $self->output('Initializing session file.');
    }

    my $session = App::Critique::Session->new(
        perl_critic_profile => $opt->perl_critic_profile,
        perl_critic_theme   => $opt->perl_critic_theme,
        perl_critic_policy  => $opt->perl_critic_policy,
        git_work_tree       => $opt->git_work_tree,
        git_branch          => $opt->git_branch,
    );

    if ( $session->session_file_exists && !$opt->force ) {
        $self->runtime_error(
            'Unable to overwrite session file (%s) without --force option.',
            $session->session_file_path
        );
    }

    eval {
        $session->store;
        1;
    } or do {
        $self->runtime_error(
            'Unable to store session file (%s) because (%s)',
            $session->session_file_path,
            $@,
        );
    };

    $self->output('Session file (%s) initialized successfully.', $session->session_file_path);
}

1;

__END__

# ABSTRACT: Initialize .critique file.

=pod

=head1 NAME

App::Critique::Command::init - Initialize .critique file

=head1 DESCRIPTION

This command will create a critique session file your F<~/.critique>
directory. This file will be used to store information about the critque
session. The specific file path for the critique session will be based
on the information provided through the command line options, and will
look something like this:

  ~/.critique/<git-repo-name>/<git-branch-name>/session.json

Note that the branch name can be C<master>, but must be specified as such.

You must also supply L<Perl::Critic> informaton must be specified, either
as a L<Perl::Critic> profile config (ex: F<perlcriticrc>) with additional
L<Perl::Critic> 'theme' expression added. Alternatively you can just
specify a single L<Perl::Critic::Policy> to use during the critique
session.

=cut
