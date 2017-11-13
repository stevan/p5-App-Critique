package App::Critique::Utils;
# ABSTRACT: Set of utilities for App::Critique

use strict;
use warnings;
use parent 'Exporter';
use Carp ();

our @EXPORT_OK = qw< editor_cmd >;

our %EDITOR_FMT = (
    'vim'         => '"+call cursor(%line%, %column%)" %filename%',
    'emacs'       => '+%line%:%column% %filename%',
    'sublimetext' => '%filename%:%line%:%column%',
);

our %EDITOR_ALIASES = (
    'subl' => 'sublimetext',
);

sub editor_cmd {
    my ( $editor, $filename, $line, $column ) = @_;

    @_ == 4
        or Carp::croak('editor_cmd( $editor, $filename, $line, $column )');

    $editor //= '';

    my $fmt = $EDITOR_FMT{$editor}
        || $EDITOR_FMT{ $EDITOR_ALIASES{$editor} // '' }
        or return;

    $fmt =~ s/%line%/$line/xmsg;
    $fmt =~ s/%column%/$column/xmsg;
    $fmt =~ s/%filename%/$filename/xmsg;

    return "$editor $fmt";
}


1;
