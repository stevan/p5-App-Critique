#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('App::Critique::Utils');
}

subtest '... testing build_editor_cmd' => sub {

    is(
        App::Critique::Utils::build_editor_cmd( 'vim', 'file.pl', '10', '20' ),
        'vim "+call cursor(10, 20)" file.pl',
        'vim returns correct command line',
    );

    is(
        App::Critique::Utils::build_editor_cmd( 'emacs', 'file.pl', '10', '20' ),
        'emacs +10:20 file.pl',
        'emacs returns correct command line',
    );

    my $subl = 'file.pl:10:20';
    is(
        App::Critique::Utils::build_editor_cmd( 'sublimetext', 'file.pl', '10', '20' ),
        "sublimetext $subl",
        'sublimetext returns correct command line',
    );

    is(
        App::Critique::Utils::build_editor_cmd( 'subl', 'file.pl', '10', '20' ),
        "subl $subl",
        'subl is the same as sublimetext',
    );

    like(
        exception{ App::Critique::Utils::build_editor_cmd( 'void', 'file.pl', '10', '20' ) },
        qr/Unable to find format string for editor \(void\)/,
        'No such editor',
    );
};

done_testing;

