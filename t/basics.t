#!../../perl

$|=1;

print "1..$tests\n";

sub ok ($$) {
    my($n, $ok) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
    if $n and $n != $t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
}


require DBI;
ok(0, 1);

import DBI;
ok(0, 1);

$switch = DBI->internal;
ok(0, ref $switch eq 'DBI::dr');

@drivers = DBI->available_drivers(); # at least 'ExampleP' should be installed
ok(0, @drivers);
ok(0, "@drivers" =~ m/ExampleP/i);	# ignore case for VMS & Win32
ok(0, "@drivers" =~ m/Sponge/i);	# ignore case for VMS & Win32

$switch->debug(0);
$switch->{DebugDispatch} = 0;	# handled by Switch
$switch->{Warn} = 1;			# handled by DBI core

ok(7, $switch->{'Attribution'} =~ m/DBI.*? Switch by Tim Bunce/);
ok(8, $switch->{'Version'} > 0);

eval { $switch->{FooBarUnknown} = 1 };
ok(9,  $@ =~ /Can't set/);

eval { $_=$switch->{BarFooUnknown} };
ok(10, $@ =~ /Can't get/);

BEGIN { $tests = 10 }
exit 0;
