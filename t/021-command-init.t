#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use App::Cmd::Tester;
use App::Critique::Tester;

BEGIN {
    use_ok('App::Critique');
}

my $TEST_REPO = App::Critique::Tester::init_test_repo();

chdir($TEST_REPO->work_tree);

my $repo = Git::Repository->new( work_tree => $TEST_REPO->work_tree );

warn "REV-PARSE: " . $repo->run(qw( rev-parse --git-dir ));
warn "BRANCH: " . $repo->run('branch');

warn "PATH: " . Path::Tiny->cwd;
warn "PATH: " . $repo->work_tree;

use Data::Dumper;
warn '-' x 80;
warn Dumper $repo;
warn Dumper $repo->options;
warn '-' x 80;
warn Dumper $TEST_REPO;
warn Dumper $TEST_REPO->options;
warn '-' x 80;

my $result = test_app(
    'App::Critique' => [
        init => (
            '--git-work-tree'      => $repo->work_tree,
            '--perl-critic-policy' => 'Variables::ProhibitUnusedVariables',
            '--verbose'            => 1
        )
    ]
);

warn '#' x 80;
warn $result->output;
warn '#' x 80;
warn $result->error;
warn '#' x 80;

done_testing;

