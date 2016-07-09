package App::Critique::Util::FileFilters;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique -ignore;
use App::Critique::Plugin::UI;

sub no_violation {
    my ( $opt, $session ) = @_;
    die 'no_violation requires a options' unless $opt;
    die 'no_violation requires a App::Critique::Session'
      unless ref($session) eq 'App::Critique::Session';
    return sub {
        my $path           = $_[0]->path->stringify;
        my $num_violations = scalar $session->perl_critic->critique($path);
        if ( $opt->verbose ) {
            if ($num_violations) {
                App::Critique::Plugin::UI::info( 'FileFilters', 'no_violation',
                    'Found %d violation(s), keeping file (%s) ',
                    $num_violations, $path );
            }
            else {
                App::Critique::Plugin::UI::info( 'FileFilters', 'no_violation',
                    'Found no violation, pruning file (%s) ', $path );
            }
        }
        return !!$num_violations;
    };
}

sub regex_filter {
    my ($opt) = @_;
    die 'regex_filter requires a options' unless $opt;
    my $f = $opt->filter;
    return sub {
        return unless $f;
        my $path = $_[0]->path->stringify;
        my $is_match = $opt->invert ? $path !~ /$f/ : $path =~ /$f/;
        if ( $opt->verbose ) {
            if ($is_match) {
                App::Critique::Plugin::UI::info( 'Matched, keeping file (%s) ',
                    $path );
            }
            else {
                App::Critique::Plugin::UI::info(
                    'Not matched, pruning file (%s) ', $path );
            }
        }
        return !!$is_match;
    };
}

sub filter {
    my ( $opt, $default ) = @_;
    die 'filter requires a options'                unless $opt;
    die 'filter requires default fall back filter' unless $default;
    my $filter;
    if ( my $f = $opt->filter ) {
        if ( ref $f eq 'CODE' ) {
            $filter = $f;
        }
        else {
            no strict 'refs';
            $filter = &{$default}($opt);
        }
    }
    return $filter;
}

1;

__END__

# ABSTRACT: Prebuilt reusable filters

=pod

=head1 NAME

App::Critique::Util::FileFilters - Collection of file filters

=head1 DESCRIPTION

This utility module defines some filters to enable code reuse.

=head1 Subroutines

=head2 no_violation

    no_violation($opt, $session)

$session must be a App::Critique::Session.



=head2 regex_filter

    regex_filter($opt)

Uses the $opt->filter to build a regex to filter the files.

If $opt->invert is present the filter is inverted.

=head2 filter

    filter($opt, $default)

if $opt contains a filter, and is not a coderef, then fall back to the specified
default, which could be any subroutine within this module.
=cut
