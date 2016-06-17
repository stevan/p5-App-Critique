package App::Critique::Command::collect;

use strict;
use warnings;

use App::Critique -command;

sub abstract    { 'Collect list of files for critiquing.' }
sub description {
q[This command will traverse the critque directory and gather all possible Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

As long as the critique session has not begun, this command can be run over
and over until the desired file list is constructed. However, once a critique
session has begun, running this command again will cause an error unless the
`force` flag is set, in which case it will use the new list and reset all
session file trackers, etc.
] }

sub opt_spec {
    [ 'filter|f=s', 'filter the files with this regular expression' ],
    [ 'force',      'force an overwrite of files in the session, regardless of status' ],
    [ 'dry-run',    'display list of files, but do not store them' ],
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
