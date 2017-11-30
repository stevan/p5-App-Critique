#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{CRITIQUE_DEBUG}   = 1;
    $ENV{CRITIQUE_VERBOSE} = 1;
    $ENV{CRITIQUE_COLOR}   = 1;
    $ENV{CRITIQUE_EDITOR}  = 'subl';
}

BEGIN {
    use_ok('App::Critique');
}

ok($App::Critique::CONFIG{DEBUG},   '... the debugging is turned on');
ok($App::Critique::CONFIG{VERBOSE}, '... the verbosity is turned on');
ok($App::Critique::CONFIG{COLOR},   '... the color is turned on');
is($App::Critique::CONFIG{EDITOR}, 'subl', '... the editor is what we expected');

done_testing;

