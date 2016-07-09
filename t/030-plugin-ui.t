#!perl

use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

BEGIN {
    use_ok('App::Critique');
}

# my $result = test_app(YourApp => [ qw(command --opt value) ]);
# is($result->output, '', '... expected output');

done_testing;

