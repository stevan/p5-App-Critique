package App::Critique::Command::prune;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny ();
use List::Util ();

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'no-violation', 'prune files that contain no Perl::Critic violations ' ],
        [],
        [ 'filter|f=s',   'filter the file list with this regular expression' ],
        [ 'invert|i',     'invert the results of the filter' ],
        [],
        [ 'dry-run',      'display pruned list of files, but do not store them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->SUPER::validate_args( $opt, $args );

    if ( $opt->filter && $opt->no_violation ) {
        error('You cannot pass both --filter and --no-violation.');
    }
    elsif ( not($opt->filter) && not($opt->no_violation) ) {
        error('You must pass either --filter or --no-violation.');
    }

}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = $self->cautiously_load_session( $opt, $args );
    info('Session file loaded.');

    my $filter;

    if ( my $f = $opt->filter ) {
        $filter =  sub {
            my $path     = $_[0]->path->stringify;
            my $is_match = $opt->invert ? $path !~ /$f/ : $path =~ /$f/;
            if ( $opt->verbose ) {
                if ( $is_match ) {
                    info('Matched, keeping file (%s) ', $path);
                }
                else {
                    info('Not matched, pruning file (%s) ', $path);
                }
            }
            return !! $is_match;
        };
    }
    elsif ( $opt->no_violation ) {
        $filter = sub {
            my $path           = $_[0]->path->stringify;
            my $num_violations = scalar $session->perl_critic->critique( $path );
            if ( $opt->verbose ) {
                if ( $num_violations ) {
                    info('Found %d violation(s), keeping file (%s) ', $num_violations, $path);
                }
                else {
                    info('Found no violation, pruning file (%s) ', $path);
                }
            }
            return !! $num_violations;
        };
    }

    my @old_files = $session->tracked_files;
    my $old_count = scalar @old_files;

    my $STOP = 0;
    local $SIG{INT} = sub { $STOP++ };

    my @new_files;

    while ( @old_files ) {
        my $f = shift @old_files;
        if ( $filter->( $f ) ) {
            push @new_files => $f;
        }
        if ($STOP) {
            warning('[processing paused]');

            my $continue = prompt_str(
                '>> (r)esume (h)alt (a)bort',
                {
                    valid   => sub { $_[0] =~ m/[rha]{1}/ },
                    default => 'r',
                }
            );

            if ( $continue eq 'r' ) {
                warning('[resuming]');
                $STOP = 0;
            }
            elsif ( $continue eq 'h' ) {
                warning('[abort processing - partial pruning]');
                push @new_files => @old_files;
                last;
            }
            elsif ( $continue eq 'a' ) {
                warning('[abort processing - results discarded]');
                return;
            }
        }
    }

    my $new_count = scalar @new_files;

    if ( $opt->dry_run ) {
        info('[dry-run] Reduced file count by %d, (old: %d, new: %d).', ($old_count - $new_count), $old_count, $new_count);
    }
    else {
        $session->set_tracked_files( @new_files );
        info('Reduced file count by %d, (old: %d, new: %d).', ($old_count - $new_count), $old_count, $new_count);

        $session->reset_file_idx;
        info('Resetting file index to 0');

        $self->cautiously_store_session( $session, $opt, $args );
        info('Session file stored successfully (%s).', $session->session_file_path);
    }
}

1;

__END__

# ABSTRACT: Prune the set of files in current critique session

=pod

=head1 NAME

App::Critique::Command::prune - Prune the set of files in current critique session

=head1 DESCRIPTION

This command will prune the set of files in the current critique session using
either a regexp path filter or by checking to see if the file contains any
L<Perl::Critic> violations.

It should be noted that this is a destructive command, meaning that if you have
begun critiquing your files and you re-run this command it will overwrite that
list and you will loose any tracking information you currently have.

=cut
