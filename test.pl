#!/usr/local/bin/perl -w

use blib;

# $Id: test.pl,v 1.23 1997/12/10 16:50:14 timbo Exp $
#
# Copyright (c) 1994, Tim Bunce
#
# See COPYRIGHT section in DBI.pm for usage and distribution rights.

# This is now mostly an empty shell. The tests have moved to t/*.t
# See t/*.t for more detailed tests.

BEGIN {
	print "$0 @ARGV\n";
	print q{DBI test application $Revision: 1.23 $}."\n";
	$| = 1;
}

use DBI;

use Config;
use Getopt::Long;
use strict;

$::opt_d = 0;
$::opt_h = 0;
$::opt_m = 0;		# basic memory leak test: "perl test.pl -m NullP"

GetOptions('d=i', 'h=i', 'l=s', 'm')
    or die "Usage: $0 [-d n] [-h n] [-m] [drivername]\n";

print "opt_d=$::opt_d\n" if $::opt_d;
print "opt_h=$::opt_h\n" if $::opt_h;
print "opt_m=$::opt_m\n" if $::opt_m;

my $count = 0;
my $ps = (-d '/proc') ? "ps -lp " : "ps -l";
my $driver = $ARGV[0] || ($::opt_m ? 'NullP' : 'ExampleP');

# Now ask for some information from the DBI Switch
my $switch = DBI->internal;
$switch->debug($::opt_h); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

$switch->{DebugDispatch} = $::opt_d if $::opt_d;
$switch->{DebugLog}      = $::opt_l if $::opt_l;

print "Available Drivers: ",join(", ",DBI->available_drivers(1)),"\n";


my $dbh = DBI->connect('', '', '', $driver);
$dbh->debug($::opt_h);

if ($::opt_m) {

    mem_test($dbh) while 1;

} else {

	# new experimental connect_test_perf method
    DBI->connect_test_perf("dbi:$driver:", '', '', {
	    dbi_loops=>10, dbi_par=>10, dbi_verb=>1
    });

	print "Testing handle creation speed...\n";
	my $null_dbh = DBI->connect('dbi:NullP:');
	my $null_sth = $null_dbh->prepare('');	# create one to warm up
	$count = 5000;
	my $i = $count;
	my $t1 = time;
	$null_sth = $null_dbh->prepare('') while $i--;
	my $dur = time - $t1 or 1;
	printf "$count NullP statement handles cycled in %d secs. Approx %d per second.\n\n",
		$dur, $count / $dur;
}

#DBI->trace(4);
print "$0 done\n";
exit 0;


sub mem_test {	# harness to help find basic leaks
    my($dbh) = @_;
	system("echo $count; $ps$$") if (($count++ % 1000) == 0);
    my $cursor_a = $dbh->prepare("select mode,ino,name from ?");
    $cursor_a->execute('/usr');
    my @row_a = $cursor_a->fetchrow;
    $cursor_a->finish;
}

# end.
