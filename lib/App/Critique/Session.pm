package App::Critique::Session;

use strict;
use warnings;

use Scalar::Util        ();
use Carp                ();

use File::HomeDir       ();
use File::Spec          ();
use Path::Class         ();
use JSON::XS            ();

use Git::Repository     ();
use Perl::Critic        ();
use Perl::Critic::Utils ();

our $JSON = JSON::XS->new->utf8->pretty->canonical;

sub new {
    my ($class, %args) = @_;

    my $git_work_tree       = $args{git_work_tree} || File::Spec->curdir;
    my $git_branch          = $args{git_branch}    || Carp::confess('You must specify a git branch');
    my $tracked_files       = $args{tracked_files} || [];
    my $perl_critic_profile = $args{perl_critic_profile};
    my $perl_critic_theme   = $args{perl_critic_theme};
    my $perl_critic_policy  = $args{perl_critic_policy};

    my $critic;
    if ( $perl_critic_policy ) {
        $critic = Perl::Critic->new( '-single_policy' => $perl_critic_policy );
    }
    else {
        $critic = Perl::Critic->new(
            ($perl_critic_profile ? ('-profile' => $perl_critic_profile) : ()),
            ($perl_critic_theme   ? ('-theme'   => $perl_critic_theme)   : ()),
        );
    }

    my $git  = Git::Repository->new( work_tree => $git_work_tree );
    my $path = $class->_generate_critique_file_path( $git->work_tree, $git_branch );

    return bless {
        git_work_tree       => $git_work_tree,
        git_branch          => $git_branch,
        perl_critic_profile => $perl_critic_profile,
        perl_critic_theme   => $perl_critic_theme,
        perl_critic_policy  => $perl_critic_policy,
        tracked_files       => $tracked_files,

        # Do Not Serialize
        _path   => $path,
        _critic => $critic,
        _git    => $git,
    } => $class;
}

sub locate_session {
    my ($class) = @_;

    my $git          = Git::Repository->new( work_tree => File::Spec->curdir );
    my ($branch)     = map /^\*\s(.*)$/, grep /^\*/, $git->run('branch');
    my $session_file = $class->_generate_critique_file_path( $git->work_tree, $branch );

    return unless -e $session_file;
    return App::Critique::Session->load( $session_file );
}

# accessors

sub tracked_files { @{ $_[0]->{tracked_files} } }

# Instance Methods

sub collect_all_perl_files {
    my ($self) = @_;

    my @files = Perl::Critic::Utils::all_perl_files( $self->{_git}->work_tree );

    return @files;
}

sub add_files_to_track {
    my ($self, @files) = @_;
    push @{ $self->{tracked_files} } => map +{
        path      => $_,
        critiqued => 0,
        edited    => 0,
        commited  => 0,
    }, @files;
}

# ...

sub pack {
    my ($self) = @_;
    return +{
        git_work_tree       => $self->{git_work_tree},
        git_branch          => $self->{git_branch},
        perl_critic_profile => $self->{perl_critic_profile},
        perl_critic_theme   => $self->{perl_critic_theme},
        perl_critic_policy  => $self->{perl_critic_policy},
        tracked_files       => $self->{tracked_files},
    };
}

sub unpack {
    my ($class, $data) = @_;
    return $class->new( %$data );
}

# ...

sub load {
    my ($class, $path) = @_;

    (-e $path && -f $path)
        || Carp::confess('Invalid path: ' . $path);

    my $file = Path::Class::File->new( $path );
    my $json = $file->slurp;
    my $data = $JSON->decode( $json );

    return $class->unpack( $data );
}

sub store {
    my ($self) = @_;

    my $file = Path::Class::File->new( $self->{_path} );
    my $data = $self->pack;

    eval {
        # JSON might die here ...
        my $json = $JSON->encode( $data );

        # if the file does not exist
        # then we should try and make
        # the path, just in case ...
        $file->parent->mkpath unless -e $file;

        # now try and write out the JSON
        my $fh = $file->openw;
        $fh->print( $json );
        $fh->close;

        1;
    } or do {
        Carp::confess('Unable to store critique session file because: ' . $@);
    };
}

# ...

sub _generate_critique_dir_path {
    my ($class, $git_work_tree, $git_branch) = @_;

    my $root = Path::Class::Dir->new( File::HomeDir->my_home );
    my $git  = Path::Class::Dir->new( $git_work_tree );

    # ~/.critique/<git-repo-name>/<git-branch-name>/session.json

    $root->subdir( '.critique' )
         ->subdir( $git->basename )
         ->subdir( $git_branch );
}

sub _generate_critique_file_path {
    my ($class, $git_work_tree, $git_branch) = @_;
    $class->_generate_critique_dir_path(
        $git_work_tree,
        $git_branch
    )->file(
        'session.json'
    );
}

1;

__END__

=pod

=cut
