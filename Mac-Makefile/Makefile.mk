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
#	EXE_FILES => [q[dbish], q[dbiproxy], q[dbiprof]]
#	NAME => q[DBI]
#	VERSION_FROM => q[DBI.pm]
#	clean => { FILES=>q[$(DISTVNAME) Perl.xsi dbish dbiproxy dbiprof dbi.prof ndtest.prt] }
#	dist => { DIST_DEFAULT=>q[clean distcheck disttest ci tardist], PREOP=>q[$(MAKE) -f Makefile.old distdir], COMPRESS=>q[gzip -v9], SUFFIX=>q[gz] }
#	dynamic_lib => { OTHERLDFLAGS=>q[0] }

# --- MakeMaker constants section:
NAME = DBI
DISTNAME = DBI
NAME_SYM = DBI
VERSION = 1.32
VERSION_SYM = 1_32
XS_VERSION = 1.32
INST_LIB = :::lib
INST_ARCHLIB = :::lib
PERL_LIB = :::lib
PERL_SRC = :::
MACPERL_SRC = :::macos:
MACPERL_LIB = :::macos:lib
PERL = :::miniperl
FULLPERL = :::perl
SOURCE =  DBI.c

MODULES = :DBI.pm \
	:lib:Bundle:DBI.pm \
	:lib:DBD:ExampleP.pm \
	:lib:DBD:NullP.pm \
	:lib:DBD:Proxy.pm \
	:lib:DBD:Sponge.pm \
	:lib:DBI:Const:GetInfo:ANSI.pm \
	:lib:DBI:Const:GetInfo:ODBC.pm \
	:lib:DBI:Const:GetInfoReturn.pm \
	:lib:DBI:Const:GetInfoType.pm \
	:lib:DBI:DBD.pm \
	:lib:DBI:FAQ.pm \
	:lib:DBI:Format.pm \
	:lib:DBI:Profile.pm \
	:lib:DBI:ProfileData.pm \
	:lib:DBI:ProfileDumper.pm \
	:lib:DBI:ProfileDumper:Apache.pm \
	:lib:DBI:ProxyServer.pm \
	:lib:DBI:PurePerl.pm \
	:lib:DBI:Shell.pm \
	:lib:DBI:W32ODBC.pm \
	:lib:Win32:DBIODBC.pm \
	DBI.pm
PMLIBDIRS = :lib


.INCLUDE : $(MACPERL_SRC)BuildRules.mk


VERSION_MACRO = VERSION
DEFINE_VERSION = -d $(VERSION_MACRO)="¶"$(VERSION)¶""
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -d $(XS_VERSION_MACRO)="¶"$(XS_VERSION)¶""

MAKEMAKER = MacintoshHD:macperl_src:perl:lib:ExtUtils:MakeMaker.pm
MM_VERSION = 5.45

# FULLEXT = Pathname for extension directory (eg DBD:Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT (eg DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = DBI
BASEEXT = DBI
ROOTEXT = 
DEFINE =  -d DBI_NO_THREADS $(XS_DEFINE_VERSION) $(DEFINE_VERSION)

# Handy lists of source code files:
XS_FILES= DBI.xs \
	Perl.xs
C_FILES = DBI.c \
	Perl.c
H_FILES = DBIXS.h \
	Driver_xst.h \
	dbd_xsh.h \
	dbi_sql.h \
	dbipport.h


.INCLUDE : $(MACPERL_SRC)ExtBuildRules.mk


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


# --- MakeMaker htmlifypods section:

htmlifypods : pure_all
	$(NOOP)


# --- MakeMaker processPL section:

ProcessPL :: dbiprof
	$(NOOP)

dbiprof :: dbiprof.PL
	$(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) dbiprof.PL dbiprof

ProcessPL :: dbiproxy
	$(NOOP)

dbiproxy :: dbiproxy.PL
	$(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) dbiproxy.PL dbiproxy

ProcessPL :: dbish
	$(NOOP)

dbish :: dbish.PL
	$(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) dbish.PL dbish


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	$(RM_RF) Perl.c DBI.c 
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"DBI\" VERSION=\"1,32,0,0\">\n}. qq{\t<TITLE>DBI</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"MacPPC\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > DBI.ppd

# --- MakeMaker postamble section:

# add the sfio.MrC.Lib to list of MrC dynamic libs

DYNAMIC_STDLIBS_MRC		+= "{{SFIO}}lib:sfio.MrC.Lib"

# add the sfio.PPC.Lib to list of PPC dynamic libs

DYNAMIC_STDLIBS_PPC		+= "{{SFIO}}lib:sfio.PPC.Lib"


# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(MACPERL_SRC)PerlInstall -l $(PERL_LIB)

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk


# End.
