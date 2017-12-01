#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('App::Critique::Utils');
}

subtest '... testing build_editor_command' => sub {

    is(
        App::Critique::Utils::build_editor_command( 'vim', 'file.pl', '10', '20' ),
        'vim "+call cursor(10, 20)" file.pl',
        'vim returns correct command line',
    );

    is(
        App::Critique::Utils::build_editor_command( 'emacs', 'file.pl', '10', '20' ),
        'emacs +10:20 file.pl',
        'emacs returns correct command line',
    );

    my $subl = 'file.pl:10:20';
    is(
        App::Critique::Utils::build_editor_command( 'sublimetext', 'file.pl', '10', '20' ),
        "sublimetext -w $subl",
        'sublimetext returns correct command line',
    );

    is(
        App::Critique::Utils::build_editor_command( 'subl', 'file.pl', '10', '20' ),
        "subl -w $subl",
        'subl is the same as sublimetext',
    );

    is(
        App::Critique::Utils::build_editor_command( 'vi', 'file.pl', '10', '20' ),
        'vi "+call cursor(10, 20)" file.pl',
        'subl is the same as sublimetext',
    );

    like(
        exception{ App::Critique::Utils::build_editor_command( 'void', 'file.pl', '10', '20' ) },
        qr/Unable to find format string for editor \(void\)/,
        'No such editor',
    );
};

done_testing;

