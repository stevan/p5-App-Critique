#!perl

use strict;
use warnings;

use Test::More;
use Test::Git;

use Path::Tiny;

BEGIN {
    use_ok('App::Critique::Session');
}

my $TEST_REPO            = test_repository( temp => [ CLEANUP => 1 ] );
my $TEST_REPO_WORK_TREE = Path::Tiny::path( $TEST_REPO->work_tree );

# Setup a basic repo, likely will want to
# move this to a test utility module soon
{
    $TEST_REPO_WORK_TREE->child('Foo.pm')->spew(q[
package Foo;
use strict;
use warnings;
sub bar { print "HELLO WORLD" }
1;
]);

    $TEST_REPO->run( add    => 'Foo.pm' );
    $TEST_REPO->run( commit => '-m', 'adding a test file' );
}

subtest '... testing session with a simple git repo' => sub {

    my $s = App::Critique::Session->new(
        git_work_tree => $TEST_REPO->work_tree
    );
    isa_ok($s, 'App::Critique::Session');

    isa_ok($s->git_work_tree, 'Path::Tiny');
    is($s->git_work_tree->stringify, $TEST_REPO->work_tree, '... got the git work tree we expected');

    is($s->git_branch, 'master', '... got the git branch we expected');

    is($s->perl_critic_policy,  undef, '... no perl critic policy');
    is($s->perl_critic_theme,   undef, '... no perl critic theme');
    is($s->perl_critic_profile, undef, '... no perl critic profile');

    is_deeply([$s->tracked_files], [], '... no tracked files');

    is($s->current_file_idx, 0, '... current file index is 0');

    isa_ok($s->session_file_path, 'Path::Tiny');
    is(
        $s->session_file_path->stringify,
        Path::Tiny::path( File::HomeDir->my_home )
            ->child( '.critique' )
            ->child( $TEST_REPO_WORK_TREE->basename )
            ->child( 'master' )
            ->child( 'session.json' )
            ->stringify,
        '... got the expected session file path'
    );

};



done_testing;

