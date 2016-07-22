package App::Critique::Plugin::FileFilter;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique -ignore;

use App::Cmd::Setup -plugin => {
    exports => [
        qw[
          file_filter
          file_filter_no_violations
          file_filter_regex
          ]
    ]
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

sub _file_filter {
    my (%args) = @_;
    Carp::confess('You must specify a `predicate` value')
        unless $args{predicate};
        
    foreach my $field (qw[ predicate success failure ]) {
        Carp::confess('If you specify a `'.$field.'` value, it must be a CODE ref')
            if $args{$field} && ref $args{$field} ne 'CODE';            
    }    
    return sub {
        my $predicate = $args{predicate} || return;
        my $success   = $args{success}   || sub {
            App::Critique::Plugin::UI::_info('Filter Match: Pass');
        };
        my $failure = $args{failure} || sub {
            App::Critique::Plugin::UI::_info('Filter Matched: Fail');
        };
        my ($file)   = @_;
        my $path     = $file->path->stringify;
        my $is_match = $predicate->($path);
        if ( $args{verbose} ) {
            if ($is_match) {
                $args{success}->( $is_match, $path );
            }
            else {
                $args{failure}->( $is_match, $path );
            }
        }
        return !!$is_match;
    };
}

sub _file_filter_no_violations {
    my (%args) = @_;
    
    Carp::confess('A session is needed for filtering files with no violations.')
        unless $args{session};
      
    return file_filter(
        %args,
        predicate =>
          sub { return scalar $args{session}->perl_critic->critique( $_[0] ) },
        success => $args{success} // sub {
            my ( $match, $path ) = @_;
            App::Critique::Plugin::UI::_info(
                'Found %d violation(s), keeping file (%s) ', $path );
        },
        failure => $args{failure} // sub {
            my ( $match, $path ) = @_;
            App::Critique::Plugin::UI::_info(
                'Found no violation, pruning file (%s)', $path );
        },
    );
}

sub _file_filter_regex {
    my (%args) = @_;
    return _file_filter(
        %args,
        predicate => sub {
            my ($path) = @_;
            my $f = $args{filter};
            return unless $f;
            return $args{invert} ? $path !~ /$f/ : $path =~ /$f/;
        },
        success => $args{success} // sub {
            my ( $match, $path ) = @_;
            App::Critique::Plugin::UI::_info( 'Matched: keeping file (%s) ',
                $path );
        },
        failure => $args{failure} // sub {
            my ( $match, $path ) = @_;
            App::Critique::Plugin::UI::_info( 'Not matched: pruning file (%s) ',
                $path );
        },
    );
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


