package App::Critique::Command::collect;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    [ 'filter|f=s', 'filter the files with this regular expression' ],
    [ 'dry-run',    'display list of files, but do not store them' ],
    [ 'verbose|v',  'display debugging information' ]
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session;
    eval {
        $session = App::Critique::Session->locate_session;
        1;
    } or do {
        my $e = $@;
        chomp $e;
        $self->runtime_error(
            "Unable to load session file (%s) because:\n    %s",
            App::Critique::Session->locate_session_file // 'undef',
            $e,
        );
    };

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
            $session->add_files_to_track( @all );
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
        $self->runtime_error('No session file found.');
    }
}

1;

__END__

# ABSTRACT: Collect list of files for critiquing.

=pod

=head1 NAME

App::Critique::Command::collect - Collect list of files for critiquing

=head1 DESCRIPTION

This command will traverse the critque directory and gather all possible Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

As long as the critique session has not begun, this command can be run over
and over until the desired file list is constructed. However, once a critique
session has begun, running this command again will cause an error unless the
`force` flag is set, in which case it will use the new list and reset all
session file trackers, etc.

=cut
