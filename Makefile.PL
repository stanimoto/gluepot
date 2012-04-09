
if (-e 'gluepot') {
    print STDERR "Generating bin/gluepot from gluepot\n";
    open my $in,  "<gluepot"     or die $!;
    open my $out, ">bin/gluepot" or die $!;
    while (<$in>) {
        s|^#!/usr/bin/env perl|#!perl|; # so MakeMaker can fix it
        print $out $_
    }
}

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'App::gluepot',
    VERSION_FROM        => 'lib/App/gluepot.pm',
    ABSTRACT => 'Get, unpack, build and install modules from CPAN.',
    PREREQ_PM => {
        'Module::Build' => 0.36,
        'ExtUtils::MakeMaker' => 6.31,
        'ExtUtils::Install' => 1.46,
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/gluepot' ],
);
