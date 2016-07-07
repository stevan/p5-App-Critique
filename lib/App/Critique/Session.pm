package App::Critique::Session;

use strict;
use warnings;

use Scalar::Util        ();
use Carp                ();

use File::HomeDir       ();
use File::Spec          ();
use Path::Tiny          ();
use JSON::XS            ();

use Git::Repository     ();
use Perl::Critic        ();
use Perl::Critic::Utils ();

use App::Critique::Session::File;

our $JSON = JSON::XS->new->utf8->pretty->canonical;

sub new {
    my ($class, %args) = @_;

    my $perl_critic_profile = $args{perl_critic_profile};
    my $perl_critic_theme   = $args{perl_critic_theme};
    my $perl_critic_policy  = $args{perl_critic_policy};

    my $critic;
    if ( $perl_critic_policy ) {
        $critic = Perl::Critic->new( '-single-policy' => $perl_critic_policy );
    }
    else {
        $critic = Perl::Critic->new(
            ($perl_critic_profile ? ('-profile' => $perl_critic_profile) : ()),
            ($perl_critic_theme   ? ('-theme'   => $perl_critic_theme)   : ()),
        );

        # inflate this as needed
        $perl_critic_profile = Path::Tiny::path( $perl_critic_profile )
            if $perl_critic_profile;
    }

    # auto-discover the current git repo and branch
    my ($git, $git_branch) = $class->_initialize_git_repo( %args );

    # now that we have worked out all the details,
    # we need to determine the path to the actual
    # critique file.
    my $path = $class->_generate_critique_file_path( $git->work_tree, $git_branch );

    my $self = bless {
        # user supplied ...
        perl_critic_profile => $perl_critic_profile,
        perl_critic_theme   => $perl_critic_theme,
        perl_critic_policy  => $perl_critic_policy,

        # auto-discovered
        git_work_tree       => Path::Tiny::path( $git->work_tree ),
        git_branch          => $git_branch,

        # local storage
        current_file_idx    => 0,
        tracked_files       => [],

        # Do Not Serialize
        _path   => $path,
        _critic => $critic,
        _git    => $git,
    } => $class;

    # handle adding tracked files
    $self->set_files_to_track( @{ $args{tracked_files} } )
        if exists $args{tracked_files};

    $self->{current_file_idx} += $args{current_file_idx}
        if exists $args{current_file_idx};

    return $self;
}

sub locate_session_file {
    my ($class, $git_work_tree) = @_;

    Carp::confess('Cannot call locate_session_file with an instance')
        if Scalar::Util::blessed( $class );

    my ($git, $git_branch) = $class->_initialize_git_repo( git_work_tree => $git_work_tree );

    my $session_file = $class->_generate_critique_file_path(
        Path::Tiny::path( $git->work_tree ),
        $git_branch
    );

    return $session_file;
}

# accessors

sub git_work_tree       { $_[0]->{git_work_tree}       }
sub git_branch          { $_[0]->{git_branch}          }
sub perl_critic_profile { $_[0]->{perl_critic_profile} }
sub perl_critic_theme   { $_[0]->{perl_critic_theme}   }
sub perl_critic_policy  { $_[0]->{perl_critic_policy}  }

sub tracked_files    { @{ $_[0]->{tracked_files} } }

sub current_file_idx { $_[0]->{current_file_idx}   }
sub inc_file_idx     { $_[0]->{current_file_idx}++ }
sub dec_file_idx     { $_[0]->{current_file_idx}-- }
sub reset_file_idx   { $_[0]->{current_file_idx}=0 }

sub session_file_path { $_[0]->{_path} }
sub git_repository    { $_[0]->{_git}  }
sub perl_critic       { $_[0]->{_critic} }

# Instance Methods

sub session_file_exists {
    my ($self) = @_;
    return !! -e $self->{_path};
}

sub set_files_to_track {
    my ($self, @files) = @_;
    @{ $self->{tracked_files} } = map {
        (Scalar::Util::blessed($_) && $_->isa('App::Critique::Session::File')
            ? $_
            : ((ref $_ eq 'HASH')
                ? App::Critique::Session::File->new( %$_ )
                : App::Critique::Session::File->new( path => $_ )))
    } @files;
}

# ...

sub pack {
    my ($self) = @_;
    return +{
        perl_critic_profile => ($self->{perl_critic_profile} ? $self->{perl_critic_profile}->stringify : undef),
        perl_critic_theme   => $self->{perl_critic_theme},
        perl_critic_policy  => $self->{perl_critic_policy},

        git_work_tree       => ($self->{git_work_tree} ? $self->{git_work_tree}->stringify : undef),
        git_branch          => $self->{git_branch},

        current_file_idx    => $self->{current_file_idx},
        tracked_files       => [ map $_->pack, @{ $self->{tracked_files} } ],
    };
}

sub unpack {
    my ($class, $data) = @_;
    return $class->new( %$data );
}

# ...

sub load {
    my ($class, $path) = @_;

    ($path->exists && $path->is_file)
        || Carp::confess('Invalid path: ' . $path);

    my $file = Path::Tiny::path( $path );
    my $json = $file->slurp;
    my $data = $JSON->decode( $json );

    return $class->unpack( $data );
}

sub store {
    my ($self) = @_;

    my $file = $self->{_path};
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

    my $root = Path::Tiny::path( File::HomeDir->my_home );
    my $git  = Path::Tiny::path( $git_work_tree );

    # ~/.critique/<git-repo-name>/<git-branch-name>/session.json

    $root->child( '.critique' )
         ->child( $git->basename )
         ->child( $git_branch );
}

sub _generate_critique_file_path {
    my ($class, $git_work_tree, $git_branch) = @_;
    $class->_generate_critique_dir_path(
        $git_work_tree,
        $git_branch
    )->child(
        'session.json'
    );
}

sub _initialize_git_repo {
    my ($class, %args) = @_;

    my $git = Git::Repository->new( work_tree => $args{git_work_tree} || File::Spec->curdir );

    # auto-discover the current git branch
    my ($git_branch) = map /^\*\s(.*)$/, grep /^\*/, $git->run('branch');

    # make sure the branch we are on is the
    # same one we are being asked to load,
    # this is very much unlikely to happen
    # but something we should die about none
    # the less.
    Carp::confess('Attempting to inflate session for branch ('.$args{git_branch}.') but branch ('.$git_branch.') is currently active')
        if exists $args{git_branch} && $args{git_branch} ne $git_branch;

    # if all is well, return ...
    return ($git, $git_branch);
}

1;

__END__

=pod

=cut
