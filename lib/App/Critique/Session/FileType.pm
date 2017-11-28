package App::Critique::Session::FileType;
use strict;
use warnings FATAL => 'all';

use Carp;

use Module::Pluggable require => 1;

my @PLUGINS_IN_USE;

sub set_plugin_set {
    my ( $class, @pl ) = @_;

    my @plugin_set;
    my $all_plugins = +{ map { $_ => 1 } $class->plugins };
    for (@pl) {
        my $pl_class = __PACKAGE__ . '::Plugin::' . $_;
        Carp::confess "No such plugin: $_" if !$all_plugins->{$pl_class};
        push @plugin_set, $pl_class;
    }

    @PLUGINS_IN_USE = @plugin_set;
    return;
}

sub matching_filetype {
    my ( $class, $fname ) = @_;
    Carp::confess "Plugins in use are not defined yet" if !@PLUGINS_IN_USE;
    foreach my $plugin (@PLUGINS_IN_USE) {
        $plugin->match_filename($fname) and return $plugin;
    }
    return;
}

# Return 'perl5' for App::Critique::Session::FileType::perl5
sub shortname {
    my ($plugin) = @_;
    if ( $plugin =~ /(?<=::)(\w+)$/ ) {
        return $1;
    }
}

1;
