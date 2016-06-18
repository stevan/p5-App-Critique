package App::Critique::Command::process;

use strict;
use warnings;

use App::Critique -command;

sub abstract    { 'Critique files.' }
sub description {
q[This command will start or resume the critique session, allowing you to
step through the files and critique them. This current state of this
processing will be stored in the critique session file and so can be
stopped and resumed at any time.

Note, this is an interactive command,
] }

sub opt_spec {
    [ 'verbose|v', 'display debugging information' ]
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    # ...

    # find the matching critique session file or throw an exception
}

sub execute {
    my ($self, $opt, $args) = @_;
    # ...
    if ( my $session = App::Critique::Session->locate_session ) {

        my @files = $session->tracked_files;

        foreach my $file ( @files ) {
            print "path: ", $file->{path}, "\n";
        }

    }
    else {
        die 'No session file found.';
    }

}



1;

__END__

=pod

=cut
