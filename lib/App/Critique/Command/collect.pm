package App::Critique::Command::collect;

use strict;
use warnings;

use List::Util ();

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'filter|f=s', 'filter the files with this regular expression' ],
        [ 'shuffle',    'shuffle the file list' ],
        [ 'dry-run',    'display list of files, but do not store them' ],
        $class->SUPER::opt_spec,
    );
}

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

        $self->output('Session file located.');

        my @all = $session->collect_all_perl_files;

        my $num_files = scalar @all;
        $self->output('Collected %d perl files for critique.', $num_files);

        if ( my $filter = $opt->filter ) {
            $self->output('Filtering file list with (%s)', $filter);
            @all = grep !/$filter/, @all;
            $self->output('... removed %d files, leaving %d to be critiqued.', ($num_files - scalar @all), scalar @all);
            $num_files = scalar @all;
        }

        if ( $opt->shuffle ) {
            @all = List::Util::shuffle( @all );
        }

        if ( $opt->verbose ) {
            foreach my $file ( @all ) {
                $self->output(
                    'Including %s',
                    Path::Class::File->new( $file )->relative( $session->git_work_tree )
                );
            }
        }

        if ( $opt->dry_run ) {
            $self->output('[dry run] %d files found, 0 files added.', $num_files);
        }
        else {
            $session->set_files_to_track( @all );
            $self->output('%d files added.', $num_files);
            $session->store;
            $self->output('Session file stored successfully (%s).', $session->session_file_path);
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

# ABSTRACT: Collect set of files for current critique session

=pod

=head1 NAME

App::Critique::Command::collect - Collect set of files for current critique session

=head1 DESCRIPTION

This command will traverse the critque directory and gather all available Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

It should be noted that this is a destructive command, meaning that if you have
begun critiquing your files and you re-run this command it will overwrite that
list and you will loose any tracking information you currently have.

=cut
