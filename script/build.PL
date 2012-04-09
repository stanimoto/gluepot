#!/usr/bin/env perl

=for developers

  NAME                          DESCRIPTION                                     repo     CPAN | wget  source  CPAN
  --------------------------------------------------------------------------------------------+--------------------
  script/gluepot.PL               frontend source                                  YES       NO |
  lib/App/gluepot/script.pm   "the gut".                                       YES      YES |            x     x
  gluepot                         standalone, packed. #!/usr/bin/env (for cp)      YES       NO |    x
  bin/gluepot                     standalone, packed. #!perl (for EUMM)             NO      YES |            x     x

=cut

open my $in,  "<", "script/gluepot.PL" or die $!;
open my $out, ">", "gluepot.tmp" or die $!;

print STDERR "Generating gluepot from script/gluepot.PL\n";

while (<$in>) {
    next if /Auto-removed/;
    s/DEVELOPERS:.*/DO NOT EDIT -- this is an auto generated file/;
    s/.*__FATPACK__/zomg_hfs(scalar `$^X -e "use App::FatPacker -run_script" file`)/e;
    print $out $_;
}

close $out;

unlink "gluepot";
rename "gluepot.tmp", "gluepot";
chmod 0755, "gluepot";

END { unlink "gluepot.tmp" }

# HFS is case sensitive, we have fatlib/version that contains Version/Requirements.pm :(
sub zomg_hfs {
    local $_ = shift;
    s!version/Requirements.pm!Version/Requirements.pm!;
    return $_;
}
