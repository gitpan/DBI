#!/usr/local/bin/perl -w
# $Id: Makefile.PL,v 1.41 1995/10/24 03:07:33 timbo Exp $

use ExtUtils::MakeMaker qw(WriteMakefile $Verbose %att);
use Config;

%opts = (
    NAME=> 'DBI',
    VERSION=> "0.64",
    dist => { DIST_CP=>'ln' },
);

# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){	# a reasonable guess
	$Verbose = 1;
	$opts{'INST_LIB'}     = $Config{'installprivlib'};
	$opts{'INST_ARCHLIB'} = $Config{'installarchlib'};
}
$opts{'DEFINE'} = '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align -Wconversion'
    if $Config{cc} eq 'gcc';	# ask gcc to be mildly paranoid


$Verbose = 1;
warn <<EOT;

    Build, TEST and INSTALL Perl 5 first. Use version 5.001m or later.

    DO NOT build the DBI under the Perl source tree.

    Use 'make test' to execute self tests.

EOT


WriteMakefile( %opts );


sub MY::post_initialize{
	# get DBIXS.h installed for access by DBD's
	$att{PM}->{'DBIXS.h'} = '$(INST_ARCHLIBDIR)/DBI/DBIXS.h';

    # default target for make's which don't understand '.SUFFIXES:'
    # (which appears as the first target).
    '
default_target: all
';
}


# --- private development stuff ---

sub MY::dist_core {
	'
dist : ci $(DIST_DEFAULT)
 
tardist : $(DISTNAME)-$(VERSION).tar.$(SUFFIX)
 
$(DISTNAME)-$(VERSION).tar.$(SUFFIX) : distdir
	$(TAR) $(TARFLAGS) $(DISTNAME)-$(VERSION).tar $(DISTNAME)-$(VERSION)
	$(COMPRESS) $(DISTNAME)-$(VERSION).tar
	$(RM_RF) $(DISTNAME)-$(VERSION)
	@chmod -w $(DISTNAME)-$(VERSION).tar.$(SUFFIX)
	mv $(DISTNAME)-$(VERSION).tar.$(SUFFIX) $$HOME/perl/db/DBI/
	@cd $$HOME/perl/db/DBI; pwd; ls -l DBI-*.tar*

rcsdiff:
	@echo "make rcsdiff V=$(V)"
	for f in RCS/*; do rcsdiff -r$(V) $$f; done 2>&1 | less

';
}

# end.
