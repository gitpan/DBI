# $Id: Makefile.PL,v 1.64 1997/09/05 19:16:40 timbo Exp $
#
#  Copyright (c) 1994,1995,1996,1997  Tim Bunce  England
#
# See COPYRIGHT section in DBI.pm for usage and distribution rights.

BEGIN { require 5.003 }

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Config;

my $os = $^O;
my $osvers = $Config{osvers};
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;  # drop sub-sub-version: 2.5.1 -> 2.5

if ($] < 5.004) {
	print "\n*** You are using an old version of Perl. ***\n";
	print "Perl 5.004 fixes many bugs in older versions and is highly recommended.\n";
    print "You may see warnings from 'pod2man' due to the old version you have.\n";
    print "You can ignore them, or, better still, upgrade to the latest release\n";
	print "of Perl (5.004_03 at the time this was written).\n\n";
}

%opts = (
	NAME=> 'DBI',
	VERSION_FROM=> 'DBI.pm',
	clean => { FILES=> '$(DISTVNAME)/' },
	dist  => {
		DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
		PREOP => '$(MAKE) -f Makefile.old distdir',
		COMPRESS => 'gzip -v9', SUFFIX => 'gz',
	},
);

$opts{'DEFINE'} = '-Wall -Wno-comment'
    if $Config{cc} eq 'gcc';	# ask gcc to be mildly pedantic

# HP-UX 9 cannot link a non-PIC object file into a shared library.
# Since the # .a libs that Oracle supplies contain non-PIC object
# files, we sadly have to build static on HP-UX 9 :(
if ($os eq 'hpux' and $osvers < 10) {
    $opts{LINKTYPE} = 'static';
    print "Warning: Forced to build static not dynamic on $os $osvers.\a\n";
    print "** Note: DBI will be built *into* a NEW perl binary. You MUST use that new perl.\n";
    print "         See README and Makefile.PL for more information.\a\n";
}

# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){	# a reasonable guess
    # $opts{'INST_LIB'}     = '$(INSTALLSITELIB)';
    # $opts{'INST_ARCHLIB'} = '$(INSTALLSITEARCH)';
	$opts{'DEFINE'}       .= ' -g -Wpointer-arith -Wcast-align -Wconversion';
}

warn <<EOT;

    Remember to actually *read* the README file!

    Build, TEST and INSTALL Perl 5 first. Use version 5.004_01 or later.

    DO NOT build the DBI under the Perl source tree.

    Use 'make test' to execute self tests.

    Install DBI (using 'make install') and delete this working directory
	before unpacking and building any DBD::* drivers.

EOT

warn "WARNING: Your GNU C compiler is very old. Please upgrade.\n"
	if ($Config{gccversion} and $Config{gccversion} =~ m/^(1|2\.[1-5])/);

$opts{'OPTIMIZE'} = '-Od'
    if ($Config{cc} eq 'cc' && $Config{osname} eq 'sco');

$Verbose = 1;
WriteMakefile( %opts );


sub MY::post_initialize {
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

    '';
}

# end.
