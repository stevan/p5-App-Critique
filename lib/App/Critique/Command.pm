package App::Critique::Command;

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny ();

use App::Cmd::Setup -command;

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'git-work-tree=s', 'git working tree, defaults to current working directory', { default => Path::Tiny->cwd } ],
        [],
        [ 'debug|d',         'display debugging information',  { default => $App::Critique::CONFIG{'DEBUG'}, implies => 'verbose' } ],
        [ 'verbose|v',       'display additional information', { default => $App::Critique::CONFIG{'VERBOSE'}                     } ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error('The git-work-tree does not exist (' . $opt->git_work_tree . ')')
        unless -d $opt->git_work_tree;
}


sub cautiously_load_session {
    my ( $self, $opt, $args ) = @_;

    return _cautiously_do_stuff(
        %$opt,
        dangerous_code => sub {
            my (%opt) = @_;
            if (
                my $session_file_path =
                App::Critique::Session->locate_session_file(
                    $opt{git_work_tree}
                )
              )
            {
                return App::Critique::Session->load($session_file_path);
            }
            else {
                error(
                    'No session file found, perhaps you forgot to call `init`.'
                );
            }
        },
        debug_error_message => sub {
            App::Critique::Plugin::UI::_error(
                "Unable to load the session file, because:\n  %s", $_[0] );
        },
        error_message => sub {
            App::Critique::Plugin::UI::_error(
'Unable to load the session file, run with --debug|d for more information'
            );
        },
    );
}

sub cautiously_store_session {
    my ($self, $session, $opt, $args) = @_;

    return _cautiously_do_stuff(
        %$opt,
        session => $session,
        dangerous_code => sub {
            my (%opt) = @_;
            $opt{session}->store;
            return $session->session_file_path;
        },
        debug_error_message => sub {
            App::Critique::Plugin::UI::_error("Unable to store the session file, because:\n  %s", $_[0]);

        },
        error_message => sub {
            App::Critique::Plugin::UI::_error(
'Unable to save the session file, run with --debug|d for more information'
            );
        },
    );
}

sub _cautiously_do_stuff {
    my (%args) = @_;
    my $evaled_return = eval { $args{dangerous_code}->(%args); } or do {
        my $e = "$@";
        chomp $e;
        if ( $args{debug} ) {
            $args{debug_error_message}->($e)
              // App::Critique::Plugin::UI::_error( "%s", $e );
        }
        else {
            $args{error_message}->(%args)
              // App::Critique::Plugin::UI::_error(
                'Dangerous code failed, run with --debug|d for more information'
              );
        }
    };

    return $evaled_return;
}




1;

__END__

# ABSTRACT: Command base class for App::Critique

=pod

=cut

