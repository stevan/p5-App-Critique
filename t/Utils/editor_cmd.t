use strict;
use warnings;
use Test::More 'tests' => 5;
use App::Critique::Utils qw< editor_cmd >;

is(
    editor_cmd( 'vim', 'file.pl', '10', '20' ),
    'vim "+call cursor(10, 20)" file.pl',
    'vim returns correct command line',
);

is(
    editor_cmd( 'emacs', 'file.pl', '10', '20' ),
    'emacs +10:20 file.pl',
    'emacs returns correct command line',
);

my $subl = 'file.pl:10:20';
is(
    editor_cmd( 'sublimetext', 'file.pl', '10', '20' ),
    "sublimetext $subl",
    'sublimetext returns correct command line',
);

is(
    editor_cmd( 'subl', 'file.pl', '10', '20' ),
    "subl $subl",
    'subl is the same as sublimetext',
);

is(
    editor_cmd( 'void', 'file.pl', '10', '20' ),
    undef,
    'No such editor',
);
