# This Makefile is for the DBI extension to perl.
#
# It was generated automatically by MakeMaker version
#  (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DEFINE => q[ -DDBI_NO_THREADS]
#	DIR => []
#	EXE_FILES => [q[dbish], q[dbiproxy]]
#	NAME => q[DBI]
#	VERSION_FROM => q[DBI.pm]
#	clean => { FILES=>q[$(DISTVNAME)/ Perl.xsi dbish dbiproxy ndtest.prt] }
#	dist => { DIST_DEFAULT=>q[clean distcheck disttest ci tardist], COMPRESS=>q[gzip -v9], SUFFIX=>q[gz], PREOP=>q[$(MAKE) -f Makefile.old distdir] }
#	dynamic_lib => { OTHERLDFLAGS=>q[0] }

# --- MakeMaker constants section:
NAME = DBI
DISTNAME = DBI
NAME_SYM = DBI
VERSION = 1.08
VERSION_SYM = 1_08
XS_VERSION = 1.08
INST_LIB = :::lib
INST_ARCHLIB = :::lib
PERL_LIB = :::lib
PERL_SRC = :::
PERL = :::miniperl
FULLPERL = :::perl
SOURCE =  DBI.c

MODULES = :lib:Bundle:DBI.pm \
	:lib:DBD:ADO.pm \
	:lib:DBD:ExampleP.pm \
	:lib:DBD:NullP.pm \
	:lib:DBD:Proxy.pm \
	:lib:DBD:Sponge.pm \
	:lib:DBI:DBD.pm \
	:lib:DBI:FAQ.pm \
	:lib:DBI:Format.pm \
	:lib:DBI:ProxyServer.pm \
	:lib:DBI:Shell.pm \
	:lib:DBI:W32ODBC.pm \
	:lib:Win32:DBIODBC.pm \
	DBI.pm
PMLIBDIRS = lib


.INCLUDE : $(PERL_SRC)BuildRules.mk


# FULLEXT = Pathname for extension directory (eg DBD:Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT (eg DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = DBI
BASEEXT = DBI
ROOTEXT = 
DEFINE =  -d DBI_NO_THREADS

# Handy lists of source code files:
XS_FILES= DBI.xs \
	Perl.xs
C_FILES = DBI.c \
	Perl.c
H_FILES = DBIXS.h \
	dbd_xsh.h \
	dbi_sql.h


.INCLUDE : $(PERL_SRC)ext:ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: DBI.exp


DBI.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "DBI", "DL_FUNCS" => {  }, "DL_VARS" => []);'


# --- MakeMaker dynamic section:

all :: dynamic

install :: do_install_dynamic

install_dynamic :: do_install_dynamic


# --- MakeMaker static section:

all :: static

install :: do_install_static

install_static :: do_install_static


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	$(RM_RF) DBI.c Perl.c :$(DISTVNAME):
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker postamble section:


# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(PERL_SRC)PerlInstall -l $(PERL_LIB)
	$(PERL_SRC)PerlInstall -l "Bird:MacPerl Ä:site_perl:"

.INCLUDE : $(PERL_SRC)BulkBuildRules.mk


# End.
