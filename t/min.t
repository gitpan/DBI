#!../../perl

$|=1;

print "1..$tests\n";

require DBI;
print "ok 1\n";

import DBI;
print "ok 2\n";

$switch = DBI->internal;
(ref $switch eq 'DBI::dr') ? print "ok 3\n" : print "not ok 3\n";

@drivers = DBI->available_drivers(); # at least 'ExampleP' should be installed
(@drivers) ? print "ok 4\n" : print "not ok 4\n";

$switch->debug(0);
$switch->{DebugDispatch} = 0;	# handled by Switch
$switch->{Warn} = 1;			# handled by DBI core

print "ok 4\n";

# --------------------

{   package DBD::Test;

    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, {
	    'Name' => 'Test',
	    'Version' => '$Revision: 1.2 $',
	    },
	    77	# 'implementors data'
	    );
	$drh;
    }
}

{   package DBD::Test::dr;
    $imp_data_size = 0;
    $imp_data_size = 0;	# avoid typo warning

    sub disconnect_all { undef }
    sub DESTROY { undef }
}

$INC{'DBD/Test.pm'} = 'dummy';	# fool require in install_driver()

$drh = DBI->install_driver('Test');
($drh) ? print "ok 5\n" : print "not ok 5\n";

(DBI::_get_imp_data($drh) == 77) ? print "ok 6\n" : print "not ok 6\n";

BEGIN { $tests = 6 }
exit 0;
