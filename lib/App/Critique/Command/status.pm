package App::Critique::Command::status;

use strict;
use warnings;

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    [ 'statistics', 'display additional statistical information' ],
    [ 'verbose|v',  'display debugging information' ]
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    # ...
}

sub execute {
    my ($self, $opt, $args) = @_;
    # ...

    if ( my $session = App::Critique::Session->locate_session ) {
        use Data::Dumper;
        print Dumper $session->pack;
    }
    else {
        die 'No session file found.';
    }

}

1;

__END__

# ABSTRACT: Display status of the current critique session.

=pod

=head1 NAME

App::Critique::Command::status - Critique all the files.

=head1 DESCRIPTION

This command will display information about the current critique session.
Among other things, this will include information about each of the files,
such as:

=over 4

=item has the file been criqued already?

=item did we perform an edit of the file?

=item have any changes been commited?

=back

=cut
