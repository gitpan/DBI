# -*- perl -*-
#
# $Id: Makefile.PL,v 10.6 1999/01/06 01:12:45 timbo Exp $
#
#  Copyright (c) 1994,1995,1996,1997  Tim Bunce  England
#
# See COPYRIGHT section in DBI.pm for usage and distribution rights.

BEGIN {
    require 5.003;
    unshift @INC, "lib";
}

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Getopt::Long;
use Config;

use Test::Harness;	# tests use it so check it's loadable early


my $os = $^O;
my $osvers = $Config{osvers};
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;  # drop sub-sub-version: 2.5.1 -> 2.5
my $ext_pl = $^O eq 'VMS' ? '.pl' : '';

$::opt_v = 0;
$::opt_g = 0;
$::opt_thread = 0;
GetOptions(qw(v! g! thread!)) or die "Invalid arguments\n";

$::opt_g &&= '-g';  # convert to actual string

if ($] < 5.004) {
    print "\n*** YOU ARE USING A VERY OLD VERSION OF PERL. ***\n\a";
    print "Perl 5.004 fixes many bugs in older versions and is highly recommended.\n";
    print "You may see warnings from 'pod2man' due to the old version you have.\n";
    print "You can ignore them, or, better still, upgrade to the latest release\n";
    print "of Perl (5.004_04 and 5.005_02 at the time this was written).\n\n";
    sleep 3;
}

if ($::opt_thread && $Config{archname} =~ /-thread\b/i) {
    print "\n*** Thread support in the DBI is known to be broken. ***\a\n";
    print   "*** You asked for it and you have been warned!       ***\a\n\n";
    sleep 3;
}


my @missing;

eval "use RPC::PlServer 0.2001 ();";
if ($@) {
    push @missing, 'RPC::PlServer';
    print "\a",<<'MSG';
*** Note:
    The optional PlRPC-modules (RPC::PlServer etc) are not installed.
    If you want to use the DBD::Proxy driver and DBI::ProxyServer
    modules, then you'll need to install the RPC::PlServer, RPC::PlClient,
    Storable and Net::Daemon modules. The DBI CPAN Bundle may help you.
    You can install them any time after installing the DBI.
    You do *not* need these modules for typical DBI usage.

MSG
    sleep 2;
}

if (@missing) {
    print <<'MSG';
Optional modules are available from any CPAN mirror, in particular
    http://www.perl.com/CPAN/modules/by-module
    http://www.perl.org/CPAN/modules/by-module
    ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

MSG
	sleep 5;
}

 
%opts = (
    NAME=> 'DBI',
    VERSION_FROM=> 'DBI.pm',
    EXE_FILES => [ "dbish$ext_pl", "dbiproxy$ext_pl" ],
    DIR => [],
    dynamic_lib => { OTHERLDFLAGS => "$::opt_g" },
    clean => { FILES=> "\$(DISTVNAME)/ Perl.xsi "
			."dbish$ext_pl dbiproxy$ext_pl ndtest.prt" },
    dist  => {
	DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
	PREOP => '$(MAKE) -f Makefile.old distdir',
	COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT_FROM} = 'DBI.pm';
    $opts{AUTHOR} = 'Tim Bunce (dbi-users@fugue.com)';
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$opts{DEFINE} = '-Wall -Wno-comment'
    if $Config{cc} eq 'gcc';	# ask gcc to be mildly pedantic

$opts{DEFINE} .= ' -DDBI_NO_THREADS' unless $::opt_thread;

# HP-UX 9 cannot link a non-PIC object file into a shared library.
# Since the # .a libs that Oracle supplies contain non-PIC object
# files, we sadly have to build static on HP-UX 9 :(
if ($os eq 'hpux' and $osvers < 10) {
    $opts{LINKTYPE} = 'static';
    print "Warning: Forced to build static not dynamic on $os $osvers.\a\n";
    print "** Note: DBI will be built *into* a NEW perl binary. You MUST use that new perl.\n";
    print "         See README and Makefile.PL for more information.\a\n";
}

if ($os eq 'MSWin32'  &&  $Config{libs} =~ /\bPerlCRT.lib\b/
    &&  -f "$Config{archlib}/CORE/PerlCRT.lib") {
    # ActiveState Perl needs this; should better be done in MakeMaker, but
    # as a temporary workaround it seems ok.
    $opts{LIBS} = "-L$Config{archlib}/CORE";
}

# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{S_ARCH_SW} && $ENV{LOGNAME} eq 'timbo'){	# a reasonable guess
    $opts{DEFINE} .= ' -g -Wpointer-arith -Wconversion';
}

warn "WARNING: Your GNU C compiler is very old. Please upgrade.\n"
	if ($Config{gccversion} and $Config{gccversion} =~ m/^(1|2\.[1-5])/);

$opts{OPTIMIZE} = '-Od'
    if ($Config{cc} eq 'cc' && $Config{osname} eq 'sco');

$Verbose = $::opt_v;
WriteMakefile( %opts );

warn <<EOT;

    Remember to actually *read* the README file!
    Build, TEST and INSTALL Perl 5 first.
    Do NOT build the DBI under the Perl source tree.
    Use 'make test' to execute self tests.
    Use 'make install' to install the DBI and then delete this working
    directory before unpacking and building any DBD::* drivers.

EOT

exit 0;


# =====================================================================

package MY;

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}

sub const_cccmd {
    my $self = shift;
    local($_) = $self->SUPER::const_cccmd(@_);
    # If perl Makefile.PL *-g* then switch on debugging
    if ($::opt_g) {
	s/\s-O\d?\b//;      # delete optimise option
	s/\s-/ -g -/;       # add -g option
    }
    $_;
}


sub post_initialize {
    my($self) = shift;

    if ($Config{privlibexp} ne $Config{sitelibexp}) {
	warn "
Warning: By default new modules are installed into your 'site_lib'
directories. Since site_lib directories come after the normal library
directories you must delete old DBI files and directories from your
'privlib' and 'archlib' directories and their auto subdirectories.
If you don't have an old version of the DBI installed you can ignore this.
";
	my $find = "find $Config{privlibexp} $Config{archlibexp} ";
	$find .= "-name 'DB*' -print | sort | uniq";
	if (open(FIND, "$find |")) {
	    my @old;
	    while(<FIND>) {
		next unless m:\bDB(I|D$):;
		next if m:^\Q$Config{sitelibexp}/:;
		next if m:^\Q$Config{sitearchexp}/:;
		next if m:^\Q$Config{man3direxp}/:;
		chop;
		push @old, $_;
	    }
	    close(FIND);
	    warn "Here's a list of probable old files and directories:\n ",
		    join("\n ",@old),"\n" if @old;
	    warn "Reinstall DBD::* drivers after deleting the listed DBD directories.\n"
		if "@old" =~ /\bDBD$/m;
	    warn "\n";
	}
    }

    # install files that DBD's may need
    my $file;
    foreach $file (qw(DBIXS.h dbi_sql.h dbd_xsh.h), <*.xst>) {
	$self->{PM}->{$file} = '$(INST_ARCHAUTODIR)/'.$file;
    }

    return '';
}


sub post_constants {

    # ensure that Driver.xst and related code gets tested

    BEGIN {
	require 'lib/DBI/DBD.pm';
	import DBI::DBD;
    }
    my $xst = dbd_postamble();
    $xst =~ s/\$\(BASEEXT\)/Perl/g;
    $xst .= '
DBI.c: Perl$(OBJ_EXT)
';

    return $xst;
}

# end.
