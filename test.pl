#!/usr/local/bin/perl -w

# $Id: test.pl,v 1.19 1997/05/06 22:23:17 timbo Exp $
#
# Copyright (c) 1994, Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# This is now mostly an empty shell. The tests have moved to t/*.t
# See t/*.t for more detailed tests.

BEGIN {
	print "$0 @ARGV\n";
	print q{DBI test application $Revision: 1.19 $}."\n";
	$| = 1;
}

use blib;

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
    DBI->connect_test_perf('', '', '', $driver, {
	    dbi_loops=>2, dbi_par=>5, dbi_verb=>1
    });
}

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
