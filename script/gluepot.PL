#!/usr/bin/env perl
# __FATPACK__
use strict;
use FindBin qw($Bin); # For dev -- Auto-removed
use lib "$Bin/../lib", "$Bin/../fatlib"; # For dev -- Auto-removed
use App::gluepot::script;

unless (caller) {
    my $app = App::gluepot::script->new;
    $app->parse_options(@ARGV);
    $app->doit or exit(1);
}

__END__

=head1 NAME

gluepot - glue services

=head1 SYNOPSIS

=head1 COMMANDS

=over 4

=item daemon-start

=item daemon-stop

=item shell

=item run

=item -h, --help

=item -V, --version

=back

=head1 COPYRIGHT

Copyright 2012- Satoshi Tanimoto.

=head1 AUTHOR

Satoshi Tanimoto

=cut
