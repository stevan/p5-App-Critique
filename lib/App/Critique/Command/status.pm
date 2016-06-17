package App::Critique::Command::status;

use strict;
use warnings;

use App::Critique -command;

sub abstract    { 'Display status of the current critique session.' }
sub description {
q[This command will display information about the current critique session.
Among other things, this will include information about each of the files,
such as:

- has the file been criqued already?
- did we perform an edit of the file?
- have any changes been commited?
] }

sub opt_spec {
    [ 'statistics', 'display additional statistical information' ],
    [ 'verbose|v',  'display debugging information' ]
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    # ...

    # find the matching critique session file or throw an exception
}

sub execute {
    my ($self, $opt, $args) = @_;
    # ...
}

1;

__END__

=pod

=cut
