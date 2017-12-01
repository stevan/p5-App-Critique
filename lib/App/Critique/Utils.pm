package App::Critique::Utils;

use strict;
use warnings;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use Carp       ();
use List::Util ();

our @EXPORT_OK = qw[ build_editor_command ];

sub import {
    my $class = shift;
    return unless @_;

    my @args = @_;
    $class->import_into( scalar caller, @args );
}

sub import_into {
    my ($from, $to, @exports) = @_;

    foreach my $export ( @exports ) {
        Carp::confess('Unable to export ('.$export.') because it is not a valid export for this module')
            if not List::Util::any { $_ eq $export } @EXPORT_OK;

        *{$to.'::'.$export} = \&{$from.'::'.$export};
    }
}

## Globals Variables ...

our %EDITOR_FMT = (
    'vim'         => '"+call cursor(%line%, %column%)" %filename%',
    'emacs'       => '+%line%:%column% %filename%',
    'sublimetext' => '-w %filename%:%line%:%column%',
);

our %EDITOR_ALIASES = (
    'subl' => 'sublimetext',
    'vi'   => 'vim',
);

## Utility functions ...

sub supported_editors        { sort keys %EDITOR_FMT     }
sub supported_editor_aliases { sort keys %EDITOR_ALIASES }

sub can_support_editor {
    my ( $editor ) = @_;

    return unless $editor;

    return $EDITOR_FMT{ $editor }
        || $EDITOR_ALIASES{ $editor }
        && $EDITOR_FMT{ $EDITOR_ALIASES{ $editor } }
}

sub build_editor_command {
    my ( $editor, $filename, $line, $column ) = @_;

    Carp::croak('You must supply an editor')
        unless $editor;

    Carp::croak('You must supply a filename')
        unless $filename;

    Carp::croak('You must supply line and column numbers')
        unless defined $line && defined $column;

    my $fmt = $EDITOR_FMT{$editor} || $EDITOR_FMT{ $EDITOR_ALIASES{$editor} // '' };

    Carp::croak('Unable to find format string for editor ('.$editor.') in %EDITOR_FMT or %EDITOR_ALIASES')
        unless $fmt;

    $fmt =~ s/%line%/$line/xmsg;
    $fmt =~ s/%column%/$column/xmsg;
    $fmt =~ s/%filename%/$filename/xmsg;

    return "$editor $fmt";
}

1;

__END__

# ABSTRACT: Set of utilities for App::Critique

=pod

=head1 DESCRIPTION

Simple set of utilities for L<App::Critique>.

=head2 FUNCTIONS

=over4

=item C<supported_editors>

Returns a list of the supported editors.

=item C<supported_editor_aliases>

Returns a list of the supported editor aliases.

=item C<can_support_editor( $editor )>

Returns boolean if this is a valid C<$editor> or editor alias.

=item C<build_editor_command( $editor, $filename, $line, $column )>

Given an C<$editor>, this will try to construct a correct the system
command to open the C<$filename> at the correct C<$line> number and
C<$column>.

=back

=cut
