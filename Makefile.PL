#!/usr/local/bin/perl -w
# $Id: Makefile.PL,v 1.55 1996/09/23 18:20:45 timbo Exp $

BEGIN { require 5.003 }

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Config;

%opts = (
	NAME=> 'DBI',
	VERSION_FROM=> 'DBI.pm',
	clean => { FILES=> '$(DISTVNAME)/' },
	dist  => { DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
				PREOP => '$(MAKE) -f Makefile.old distdir' },
);

$opts{'DEFINE'} = '-Wall -Wno-comment'
    if $Config{cc} eq 'gcc';	# ask gcc to be mildly pedantic

# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){	# a reasonable guess
    # $opts{'INST_LIB'}     = '$(INSTALLSITELIB)';
    # $opts{'INST_ARCHLIB'} = '$(INSTALLSITEARCH)';
	$opts{'DEFINE'}       .= ' -g -Wpointer-arith -Wcast-align -Wconversion';
}

warn <<EOT;

    Remember to actually *read* the README file!

    Build, TEST and INSTALL Perl 5 first. Use version 5.002beta2 or later.

    DO NOT build the DBI under the Perl source tree.

    Use 'make test' to execute self tests.

    Install DBI (using 'make install' before building DBD::* drivers.

EOT

warn "WARNING: Your GNU C compiler is very old. Please upgrade.\n"
	if ($Config{gccversion} and $Config{gccversion} =~ m/^(1|2\.[1-5])/);

$Verbose = 1;
WriteMakefile( %opts );


sub MY::post_initialize {
    my($self) = shift;

    if ($Config{privlibexp} ne $Config{sitelibexp}) {
	warn "
WARNING! By default new modules are installed into your 'site_lib'
directories. Since site_lib directories come after the normal library
directories you MUST delete old DBI files and directories from your
'privlib' and 'archlib' directories and their auto subdirectories.
";
	my $find = "find $Config{privlibexp} $Config{archlibexp} ";
	$find .= "-name 'DB*' -print | sort | uniq";
	if (open(FIND, "$find |")) {
	    my @old;
	    while(<FIND>) {
		next unless m:\bDB(I|D$):;
		next if m:^$Config{sitelibexp}/:;
		next if m:^$Config{sitearchexp}/:;
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

    # get DBIXS.h installed for access by DBD's
    $self->{PM}->{'DBIXS.h'} = '$(INST_ARCHLIBDIR)/DBI/DBIXS.h';
    '';
}

# end.
