#!perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/lib";

use Test::More;

use App::Critique::Tester;

BEGIN {
    use_ok('App::Critique');
}

my $test_repo = App::Critique::Tester::init_test_repo();
my $work_tree = $test_repo->dir;
my $work_base = Path::Tiny::path( $work_tree )->basename;

subtest '... testing init' => sub {

    my ($out, $err) = App::Critique::Tester::run(
        init => (
            '-v',
            '--git-work-tree', $work_tree,
            '--perl-critic-policy', 'Variables::ProhibitUnusedVariables'
        ),
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;

    my @good = (
        qr/Attempting to initialize session file/,
        qr/\-\-perl\-critic\-policy\s+\= Variables\:\:ProhibitUnusedVariables/,
        qr/perl_critic_policy\s+\= Variables\:\:ProhibitUnusedVariables/,
        qr/Successuflly created session/,
        qr/git_work_tree\s+\= $work_tree/,
        qr/Session file \(.*\) initialized successfully/,
        qr/\.critique\/$work_base\/master\/session\.json/,
    );

    my @bad = (
        qr/Overwriting session file/,
        qr/Unable to overwrite session file/,
        qr/Unable to store session file/,
    );

    like   $out, $_, '... matched '.$_.' correctly'      foreach @good;
    unlike $out, $_, '... failed match '.$_.' correctly' foreach @bad;

};

subtest '... testing collect' => sub {

    my ($out, $err) = App::Critique::Tester::run(
        collect => (
            '-v',
            '--git-work-tree', $work_tree,
        ),
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;

    my @good = (
        qr/Session file loaded/,
        qr/Collected 6 perl files for critique/,
        qr/Including bin\/my-app/,
        qr/Including lib\/My\/Test\/WithoutViolations\.pm/,
        qr/Including lib\/My\/Test\/WithViolations\.pm/,
        qr/Including share\/debug\.pl/,
        qr/Including t\/000-test-with-violations\.t/,
        qr/Including t\/001-test-without-violations\.t/,
        qr/Sucessfully added 6 files/,
        qr/Session file stored successfully/,
        qr/\.critique\/$work_base\/master\/session\.json/,
    );

    my @bad = (
        qr/Unable to load session file/,
        qr/Unable to store session file/,
        qr/Shuffling file list/,
        qr/\[dry run\]/,
    );

    like   $out, $_, '... matched '.$_.' correctly'      foreach @good;
    unlike $out, $_, '... failed match '.$_.' correctly' foreach @bad;

};

subtest '... testing status' => sub {

    my ($out, $err) = App::Critique::Tester::run(
        status => (
            '-v',
            '--git-work-tree', $work_tree,
        ),
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;

    my @good = (
        qr/Session file loaded/,
        qr/perl_critic_policy\s+\: Variables\:\:ProhibitUnusedVariables/,
        qr/git_work_tree\s*\: $work_tree/,
            qr/bin\/my-app/,
            qr/lib\/My\/Test\/WithoutViolations\.pm/,
            qr/lib\/My\/Test\/WithViolations\.pm/,
            qr/share\/debug\.pl/,
            qr/t\/000-test-with-violations\.t/,
            qr/t\/001-test-without-violations\.t/,
        qr/TOTAL\: 6 files/,
        qr/\.critique\/$work_base\/master\/session\.json/,
    );

    my @bad = (
        qr/Unable to load session file/,
        qr/Unable to store session file/,
    );

    like   $out, $_, '... matched '.$_.' correctly'      foreach @good;
    unlike $out, $_, '... failed match '.$_.' correctly' foreach @bad;

};

App::Critique::Tester::teardown_test_repo( $test_repo );

done_testing;

