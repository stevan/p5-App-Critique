package App::Critique::Session::FileType::perl5;
use strict;
use warnings;

use parent 'App::Critique::Session::File';

# NOTE:
# This was mostly taken from the guts of
# Perl::Critic::Util::{_is_perl,_is_backup}
# - SL
sub match_filename {
    my ($class, $file) = @_;

    # skip all the backups
    return 0 if $file =~ m{ [.] swp \z}xms;
    return 0 if $file =~ m{ [.] bak \z}xms;
    return 0 if $file =~ m{  ~ \z}xms;
    return 0 if $file =~ m{ \A [#] .+ [#] \z}xms;

    # but grab the perl files
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;
    return 1 if $file =~ m{ [.] psgi  \z}xms;
    return 1 if $file =~ m{ [.] cgi   \z}xms;

    # if we have to, check for shebang
    my $first;
    {
        open my $fh, '<', $file or return 0;
        $first = <$fh>;
        close $fh;
    }

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return 0;
}

sub save_ppi {
    my ($self, $doc) = @_;
    $doc->save($self->path->stringify);
}

sub critique {
    my ($self, $session) = @_;
    my @violations = $session->perl_critic->critique( $self->path->stringify );
    return @violations;
}


1;