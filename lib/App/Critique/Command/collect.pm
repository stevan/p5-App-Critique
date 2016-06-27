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

sub validate_args {
    my ($self, $opt, $args) = @_;
    # ...
}

sub execute {
    my ($self, $opt, $args) = @_;
    # ...

    if ( my $session = eval { App::Critique::Session->locate_session } ) {

        my @all = $session->collect_all_perl_files;

        if ( my $filter = $opt->filter ) {
            @all = grep !/$filter/, @all,
        }

        if ( $opt->dry_run ) {
            $self->output( $_ ) foreach @all;
        }
        else {
            $session->add_files_to_track( @all );
            $session->store;
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
