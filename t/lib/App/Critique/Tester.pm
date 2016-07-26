package App::Critique::Tester;

use strict;
use warnings;

use Path::Tiny ();
use Test::Git  ();

sub init_test_repo {
    my $test_repo  = Test::Git::test_repository( temp => [ CLEANUP => 1 ] );
    my $work_tree  = Path::Tiny::path( $test_repo->work_tree );

    # grab the test files for the repo
    _copy_full_tree(
        from => Path::Tiny->cwd->child('devel/git/test_repo'),
        to   => $work_tree
    );

    $test_repo->run( add    => '*' );
    $test_repo->run( commit => '-m', 'initial commit' );

    return $test_repo;
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
