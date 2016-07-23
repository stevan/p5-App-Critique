package App::Critique::Plugin::FileFilter;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique -ignore;

use App::Cmd::Setup -plugin => {
    exports => [qw[
        file_filter
        file_filter_no_violations
        file_filter_regex
    ]]
};

sub file_filter {
    my ( $plugin, $cmd, @args ) = @_;
    return _file_filter(@args);
}

sub file_filter_no_violations {
    my ( $plugin, $cmd, @args ) = @_;
    return _file_filter_no_violations(@args);
}

sub file_filter_regex {
    my ( $plugin, $cmd, @args ) = @_;
    return _file_filter_regex(@args);
}

## ...

sub _file_filter {
    my %args = @_;

    Carp::confess('You must specify a `predicate` value')
        unless $args{predicate};

    foreach my $field (qw[ predicate success failure ]) {
        Carp::confess('If you specify a `'.$field.'` value, it must be a CODE ref')
            if $args{$field} && ref $args{$field} ne 'CODE';
    }

    my $predicate = $args{predicate};
    my $verbose   = !!$args{verbose};
    my $success   = $args{success} || sub { App::Critique::Plugin::UI::_info('File matched')       };
    my $failure   = $args{failure} || sub { App::Critique::Plugin::UI::_info('File did not match') };

    return sub {
        my $path     = $_[0]->path->stringify;
        my $is_match = $predicate->( $path );
        ($verbose && $is_match)
            ? $success->( $is_match, $path )
            : $failure->( $is_match, $path );
        return !!$is_match;
    };
}

sub _file_filter_no_violations {
    my %args = @_;

    Carp::confess('A session is needed for filtering files without violations.')
        unless Scalar::Util::blessed( $args{session} )
            && $args{session}->isa('App::Critique::Session');

    Carp::confess('You cannot pass a predicate when filtering on violations.')
        if $args{predicate};

    my $session = delete $args{session};
    $args{predicate} = sub { scalar $session->perl_critic->critique( $_[0] ) };

    # some defaults ...
    $args{success} ||= sub { App::Critique::Plugin::UI::_info('Found %d violation(s), keeping file (%s) ', $_[1] ) };
    $args{failure} ||= sub { App::Critique::Plugin::UI::_info('Found no violation, pruning file (%s)',     $_[1] ) };

    return _file_filter( %args );
}

sub _file_filter_regex {
    my %args = @_;

    Carp::confess('A `filter` is required ')
        unless $args{filter};

    Carp::confess('You cannot pass a predicate when filtering with a regex.')
        if $args{predicate};

    my $filter = delete $args{filter};
    my $invert = !! delete $args{invert};

    $args{predicate} = sub { $invert ? $_[0] !~ /$filter/ : $_[0] =~ /$filter/ };

    # some defaults ...
    $args{success} ||= sub { App::Critique::Plugin::UI::_info( 'Matched: keeping file (%s) ',     $_[1] ) };
    $args{failure} ||= sub { App::Critique::Plugin::UI::_info( 'Not matched: pruning file (%s) ', $_[1] ) };

    return _file_filter( %args );
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

=head2 file_filter_no_violations

    file_filter_no_violations(%$opt, seassion => $session)

$session must be a App::Critique::Session.



=head2 file_filter_regex

    file_filter_regex(%$opt)

Uses the $opt->filter to build a regex to filter the files.

If $opt->invert is present the filter is inverted.

=head2 file_filter

    my $predicate = sub {
        my ($path) = @_;
        return -f $path;
    }
    file_filter(%$opt, predicate => $predicate)

file_filer requires a predicate coderef that will be used to test against
a file.

Other options are:
success: a coderef called if in verbose and predicate coderef makes a match
faulure: a coderef called if in verbose and predicate coderef fails to match

=cut


