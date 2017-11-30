package App::Critique::Command::tutorial;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique -command;

sub opt_spec      { return ([]) }
sub validate_args { 1 }
sub execute       { info( $_[0]->description ) }

1;

__END__

# ABSTRACT: Tutorial about how to use critique

=pod

=head1 DESCRIPTION

Here is a short description of one my workflows. One thing to note is
that there is a pretty extensive help system here, so anytime you need
more info you can just do F<critique help> or F<critique help $command_name>
and get more info.

=head2 Setup

The very first thing you need to do is navigate to a git checkout
directory. Just like F<git> itself, F<critique> needs a working
directory to do its work in.

The second thing you need to do is to set the editor that F<critique>
will use when opening up files to fix a violation. This is as simple
as setting the C<CRITIQUE_EDITOR> environment variable to one of the
supported editors.

The currently supported editors are F<vim>, F<emacs> and F<sublimetext>;
along with supporting F<subl> as an alias for F<sublimetext>.

=head2 Initialize

Next you need to initialise a F<critique> session, I have found that
focusing on a single L<Perl::Critic> policy at a time can be helpful
and so I use the line below to initialize my session.

  > critique init -v --perl-critic-policy Variables::ProhibitUnusedVariables

You will likely want to include the C<-v> (verbose) flag at a minimum,
but there is also a C<-d> (debug) flag which can be helpful.

=head2 Collect

Next you want to ask F<critique> to find all the files you want to
process. This will basically just traverse the directory tree and
find all the available perl files, and looks like this:

  > critique collect -v --root lib/ExampleCompany/

You can also provide different criteria to help create the file list
that you want. You can do this in a few ways, here are some examples.

  > critique collect -v --root lib/ --filter ExampleCompany/Db/

This would traverse the F<lib/> directory, but exclude any paths
which match the C<--filter> passed.

  > critique collect -v --root lib/ --match /Db/

You can also specify what to include using the C<--match> argument,
the above will traverse F<lib/> but only match files which have
a F</Db/> folder in their path.

  > critique collect -v --root lib/ --no-violation

You can also tell F<critique> to only collect files which have a
L<Perl::Critic> violation in them.

Lastly, it is possible to combine these three arguments (C<--filter>,
C<--match> and C<--no-violation>) in any way you choose.

Note that this is a destructive command, it will overwrite any
previous files and file associated settings. It is possible however
to use C<--dry-run> flag to specify a non-destructuve test run.

Note that if you need to process a lot of files then it might be
worth it to also set the C<--num_procs> or C<-n> argument to tell
F<critique> to parallellize the collection process.

=head2 Status

So at this point it is good to know about the C<status> command. The
simplest version will just display information about the files that
have been collected and your current status in the F<critique> session.

  > critique status

There is also additonal information available in (C<-v>) verbose mode
including the associated C<git> commit shas for each file and the
F<critique> session configuration information. Sometimes this is a lot
of information, so I recommend running it through a pager program like
C<more> or C<less>.

  > critique status -v | more

It is useful to run this command regularly and take a look at the status
of your work.

=head2 Process

So, now onto the actual processing of files, the C<process> command will
do this one file at a time in a loop. If at any point you want to stop
processing it is possible to just press C<Cntl-C> to halt and F<critique>
will make every effort to save state.

  > critique process -v

This is the only interactive command in this tool and I suggest you
use it a few times and read the output carefully. No tutorial I could
write will replace just using it a little.

As mentioned above, a simple C<Cntl-C> will exit the current processing
loop. When you resume, you can either pick up where F<critique> thinks
you left off, or you can use the C<--back> or C<--next> arguments to
move backwards and forwards through history. Additionaly you can use the
C<--reset> flag to start from the very beginning of the list again.

Lastly, keep in mind that this tool is non-destructive, meaning that it
if things don't work correctly, it is as simple as just pressing C<Cntl-C>
and repairing your C<git> checkout manually.

=cut
