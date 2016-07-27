package App::Critique::Tester;

use strict;
use warnings;

use Path::Tiny ();

use Git::Wrapper;

my %TEMP_WORK_TREES;

sub init_test_repo {

    # grab the test files for the repo
    my $work_tree = Path::Tiny::tempdir( CLEANUP => 1 );
    _copy_full_tree(
        from => Path::Tiny->cwd->child('devel/git/test_repo'),
        to   => $work_tree
    );

    # and then create, add and commit
    my $test_repo = Git::Wrapper->new( $work_tree );
    $test_repo->init;
    $test_repo->add( '*' );
    $test_repo->commit({ message => 'initial commit' });

    $TEMP_WORK_TREES{ $test_repo } = $work_tree;

    return $test_repo;
}

sub teardown_test_repo {
    my $test_repo = $_[0];
    my $work_tree = delete $TEMP_WORK_TREES{ $test_repo };
    undef $work_tree;
}

# ...

sub _copy_full_tree {
    my %args = @_;

    my $from = $args{from};
    my $to   = $args{to};

    foreach my $from_child ( $from->children( qr/^[^.]/ ) ) {
        my $to_child = $to->child( $from_child->basename );

        if ( -f $from_child ) {
            $from_child->copy( $to_child );
        }
        elsif ( -d $from_child ) {
            $to_child->mkpath unless -e $to_child;
            _copy_full_tree(
                from => $from_child,
                to   => $to_child,
            );
        }
    }
}

1;

__END__
