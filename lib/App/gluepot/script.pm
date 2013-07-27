package App::gluepot::script;
use strict;
use Cwd ();
use Sys::Hostname ();
use Getopt::Long ();
use YAML ();

our $VERSION = "0.02";

sub new {
    my $class = shift;

    bless {
        argv => [],
        config_file => 'gluepot.yaml',
        default_cluster => '__default__',
        env => {},
        @_,
    }, $class;
}

sub parse_options {
    my $self = shift;

    local @ARGV = @{$self->{argv}};
    push @ARGV, @_;

    Getopt::Long::Configure(qw(bundling));
    Getopt::Long::GetOptions(
        'h|help' => sub { $self->{pre_action} = 'show_help' },
        'V|version' => sub { $self->{pre_action} = 'show_version' },
        'c|config=s' => \$self->{config_file},
        'cluster=s' => \$self->{force_cluster},
        'default-cluster=s' => \$self->{default_cluster},
    );

    $self->{argv} = \@ARGV;
}

sub doit {
    my $self = shift;

    if (my $action = $self->{pre_action}) {
        $self->$action() and return 1;
    }

    $self->process_env;

    my $subcmd = shift @{$self->{argv}};
    $subcmd =~ s/-/_/g;
    if (my $sub = $self->can("subcmd_$subcmd")) {
        $sub->($self) and return 1;
    }
}

sub config {
    my $self = shift;
    $self->{config} ||= do {
        YAML::LoadFile($self->{config_file});
    };
    return $self->{config};
}

sub setenv {
    my($self, $name, $value) = @_;
    $ENV{$name} = $self->{env}{$name} = $value;
}

sub hostname {
    my $self = shift;
    $self->{hostname} ||= lc Sys::Hostname::hostname();
    $ENV{GLUEPOT_HOSTNAME} = $self->{hostname};
    return $self->{hostname};
}

sub cluster {
    my $self = shift;
    $self->{cluster} ||= do {
        my $clu;
        if ($self->{force_cluster}) {
            $clu = $self->{force_cluster};
        }
        else {
            $clu = $self->{default_cluster};
            for my $h (keys %{$self->config->{host}}) {
                if ($self->hostname =~ /^\Q$h\E/) {
                    $clu = $self->config->{host}{$h}{cluster};
                    last;
                }
            }
        }
        $clu;
    };
    $ENV{GLUEPOT_CLUSTER} = $self->{cluster};
    return $self->{cluster};
}

sub process_env {
    my $self = shift;

    # populate envs
    $self->hostname;
    $self->cluster;

    my $envs = $self->config->{cluster}{$self->cluster}{env};
    $envs = [ $envs ] if ref $envs ne 'ARRAY';

    for my $env (@$envs) {
        next unless $env;
        open my $fh, '<', $env or die "Cannot open $env: $!";
        while (<$fh>) {
            chomp;
            my($name, $value) = split /\s*=\s*/, $_, 2;
            $self->setenv($name => $value);
        }
    }
}

sub print_supervisord_conf {
    my $self = shift;

    my @envs;
    while (my($key, $val) = each %{$self->{env}}) {
        push @envs, "$key=$val";
    }

    my $path = $self->config->{cluster}{$self->cluster}{procfile} || 'Procfile';
    open my $procfile, '<', $path or die "Cannot open $path: $!";
    while (<$procfile>) {
        chomp;
        my($name, $command) = split /\s*:\s*/, $_, 2;
        $command =~ s/(?:\$([A-Z0-9_]+))/$ENV{$1}/eg;
        printf "[program:%s]\n", $name;
        printf "command=%s\n", $command;
        printf "environment=%s\n", join(',', @envs);
        print "\n";
    }
}

sub subcmd_svconf {
    my $self = shift;
    $self->print_supervisord_conf;
}

sub subcmd_run {
    my $self = shift;
    exec(join ' ', @{$self->{argv}});
}

sub show_help {
    my $self = shift;
    print "HAAAAAAAALP!\n";
    return 1;
}

sub show_version {
    print "gluepot (App::gluepot) version $VERSION\n";
    return 1;
}

1;
__DATA__
[unix_http_server]
file = /tmp/supervisord.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisord]

[supervisorctl]
serverurl = unix:///tmp/supervisord.sock
prompt = supervisor

