#!/usr/local/bin/perl -w
# $Id: Makefile.PL,v 1.44 1996/01/29 20:29:19 timbo Exp $

require 5.002;

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Config;

%opts = (
	NAME=> 'DBI',
	VERSION_FROM=> 'DBI.pm',
	dist => { DIST_DEFAULT=> 'clean distcheck disttest ci tardist'},
);

$opts{'DEFINE'} = '-Wall -pedantic -Wno-comment'
    if $Config{cc} eq 'gcc';	# ask gcc to be mildly pedantic

# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){	# a reasonable guess
    $opts{'INST_LIB'}     = '$(INSTALLPRIVLIB)';
    $opts{'INST_ARCHLIB'} = '$(INSTALLARCHLIB)';
	$opts{'DEFINE'}       .= ' -g -Wpointer-arith -Wcast-align -Wconversion';
}

warn <<EOT;

    Remember to actually *read* the README file!

    Build, TEST and INSTALL Perl 5 first. Use version 5.002beta2 or later.

    DO NOT build the DBI under the Perl source tree.

    Use 'make test' to execute self tests.

    Install DBI (using 'make install' before building DBD::* drivers.

EOT

$Verbose = 1;
WriteMakefile( %opts );


sub MY::post_initialize {
    my($self) = shift;
	
    # get DBIXS.h installed for access by DBD's
    $self->{PM}->{'DBIXS.h'} = '$(INST_ARCHLIBDIR)/DBI/DBIXS.h';
    '';
}


# --- private development stuff ---

sub MY::__old__dist_core {
    my($self) = shift;
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
