#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'App::gluepot' ) || print "Bail out!\n";
    use_ok( 'App::gluepot::script' ) || print "Bail out!\n";
}

diag( "Testing App::gluepot $App::gluepot::VERSION, Perl $], $^X" );
