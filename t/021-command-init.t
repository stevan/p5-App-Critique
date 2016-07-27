#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib";

use Test::More;

use IPC::Run ();

use App::Cmd::Tester;
use App::Critique::Tester;

BEGIN {
    use_ok('App::Critique');
}

my $TEST_REPO = App::Critique::Tester::init_test_repo();
my $WORK_TREE = $TEST_REPO->dir;
my $CRITIQUE  = "$FindBin::Bin/../bin/critique";

my ($in, $out, $err);

my @lines = IPC::Run::run(
    [
        'perl', $CRITIQUE,
            'init', '-v',
            '--git-work-tree', $WORK_TREE,
            '--perl-critic-policy', 'Variables::ProhibitUnusedVariables'
    ],
    \$in, \$out, \$err
) or die "critique: $?";

warn '#' x 80;
warn join '' => $out;
warn '#' x 80;

App::Critique::Tester::teardown_test_repo( $TEST_REPO );

done_testing;

