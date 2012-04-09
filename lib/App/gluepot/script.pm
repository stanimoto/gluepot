package App::gluepot::script;
use strict;
use Cwd ();
use Sys::Hostname ();
use Getopt::Long ();
use YAML ();

our $VERSION = "0.01";

sub new {
    my $class = shift;

    bless {
        argv => [],
        config_file => 'gluepot.yaml',
        default_cluster => 'default',
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
        'default-cluster=s' => \$self->{default_cluster},
    );

    $self->{argv} = \@ARGV;
}

sub doit {
    my $self = shift;

    if (my $action = $self->{pre_action}) {
        $self->$action() and return 1;
    }

    $self->process_environment;
    $self->write_supervisord_conf;

    my $subcmd = shift @{$self->{argv}};
    $subcmd =~ s/-/_/g;
    if (my $sub = $self->can("subcmd_$subcmd")) {
        $sub->($self) and return 1;
    } else {
        $self->pass_svctl($subcmd) and return 1;
    }
}

sub config {
    my $self = shift;
    $self->{config} ||= do {
        YAML::LoadFile($self->{config_file});
    };
    return $self->{config};
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
        my $clu = $self->{default_cluster};
        for my $h (keys %{$self->config->{host}}) {
            if ($self->hostname =~ /^\Q$h\E/) {
                $clu = $self->config->{host}{$h}{cluster};
                last;
            }
        }
        $clu;
    };
    $ENV{GLUEPOT_CLUSTER} = $self->{cluster};
    return $self->{cluster};
}

sub process_environment {
    my $self = shift;
    my $env = $self->config->{cluster}{$self->cluster}{environment};
    for my $name (keys %$env) {
        my $value = $env->{$name};
        $value =~ s/{([A-Z0-9_]+)}/$ENV{$1}/eg;
        $ENV{$name} = $value;
    }
}

sub write_supervisord_conf {
    my $self = shift;

    open my $out, '>', 'supervisord.conf.tmp' or die $!;
    print $out <DATA>;

    my $sv = $self->config->{cluster}{$self->cluster}{service};

    for my $service (@$sv) {
        printf $out "[%s]\n", $service->{section};
        for my $opt_key (keys %{$service->{options}}) {
            printf $out "%s = %s\n", $opt_key, $service->{options}{$opt_key};
        }
        print $out "\n";
    }
    close $out;

    rename 'supervisord.conf.tmp' => 'supervisord.conf';
    unlink 'supervisord.conf.tmp';
}

sub subcmd_daemon_start {
    my $self = shift;
    if (system('supervisord') != 0) {
        print "Failed to start daemon: $! $?\n";
        return;
    }
    print "Started...\n";
    return 1;
}

sub subcmd_daemon_stop {
    my $self = shift;
    if (system('supervisorctl', 'shutdown') != 0) {
        print "Failed to stop daemon: $! $?\n";
        return;
    }
    return 1;
}

sub subcmd_shell {
    my $self = shift;
    exec qw(supervisorctl);
}

sub subcmd_run {
    my $self = shift;
    exec(join ' ', @{$self->{argv}});
}

sub pass_svctl {
    my $self = shift;
    my $cmd = shift;
    if (system('supervisorctl', $cmd, @{$self->{argv}}) != 0) {
        print "Failed to exec $cmd\n";
        return;
    }
    return 1;
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

