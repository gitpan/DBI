# This Makefile is for the DBI extension to perl.
#
# It was generated automatically by MakeMaker version
# 5.42 (Revision: 1.216) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DEFINE => q[-Wall -Wno-comment -DDBI_NO_THREADS]
#	DIR => []
#	EXE_FILES => [q[dbish], q[dbiproxy]]
#	NAME => q[DBI]
#	VERSION_FROM => q[DBI.pm]
#	clean => { FILES=>q[$(DISTVNAME)/ Perl.xsi dbish dbiproxy ndtest.prt] }
#	dist => { DIST_DEFAULT=>q[clean distcheck disttest ci tardist], COMPRESS=>q[gzip -v9], SUFFIX=>q[gz], PREOP=>q[$(MAKE) -f Makefile.old distdir] }
#	dynamic_lib => { OTHERLDFLAGS=>q[0] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /opt/perl5.004_04/lib/sun4-solaris/5.00404/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS = -fpic
CCDLFLAGS =  
DLEXT = so
DLSRC = dl_dlopen.xs
LD = gcc
LDDLFLAGS = -G -L/usr/local/lib -L/opt/gnu/lib
LDFLAGS =  -L/usr/local/lib -L/opt/gnu/lib
LIBC = /lib/libc.so
LIB_EXT = .a
OBJ_EXT = .o
RANLIB = :
SO = so
EXE_EXT = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = DBI
DISTNAME = DBI
NAME_SYM = DBI
VERSION = 1.1380
VERSION_SYM = 1_1380
XS_VERSION = 1.1380
INST_BIN = ./blib/bin
INST_EXE = ./blib/script
INST_LIB = ./blib/lib
INST_ARCHLIB = ./blib/arch
INST_SCRIPT = ./blib/script
PREFIX = /opt/perl5.004_04
INSTALLDIRS = site
INSTALLPRIVLIB = $(PREFIX)/lib
INSTALLARCHLIB = $(PREFIX)/lib/sun4-solaris/5.00404
INSTALLSITELIB = $(PREFIX)/lib/site_perl
INSTALLSITEARCH = $(PREFIX)/lib/site_perl/sun4-solaris
INSTALLBIN = $(PREFIX)/bin
INSTALLSCRIPT = $(PREFIX)/bin
PERL_LIB = /opt/perl5.004_04/lib
PERL_ARCHLIB = /opt/perl5.004_04/lib/sun4-solaris/5.00404
SITELIBEXP = /opt/perl5.004_04/lib/site_perl
SITEARCHEXP = /opt/perl5.004_04/lib/site_perl/sun4-solaris
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE
PERL = /opt/perl5.004_04/bin/perl
FULLPERL = /opt/perl5.004_04/bin/perl

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"

MAKEMAKER = /opt/perl5.004_04/lib/ExtUtils/MakeMaker.pm
MM_VERSION = 5.42

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)  !!! Deprecated from MM 5.32  !!!
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = DBI
BASEEXT = DBI
DLBASE = $(BASEEXT)
VERSION_FROM = DBI.pm
DEFINE = -Wall -Wno-comment -DDBI_NO_THREADS
OBJECT = $(BASEEXT)$(OBJ_EXT)
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= DBI.xs \
	Perl.xs
C_FILES = DBI.c \
	Perl.c
O_FILES = DBI.o \
	Perl.o
H_FILES = DBIXS.h \
	dbd_xsh.h \
	dbi_sql.h \
	dbipport.h
MAN1PODS = dbiproxy \
	dbish
MAN3PODS = DBI.pm \
	lib/Bundle/DBI.pm \
	lib/DBD/ADO.pm \
	lib/DBD/Multiplex.pm \
	lib/DBD/Proxy.pm \
	lib/DBI/DBD.pm \
	lib/DBI/FAQ.pm \
	lib/DBI/Format.pm \
	lib/DBI/ProxyServer.pm \
	lib/DBI/Shell.pm \
	lib/DBI/W32ODBC.pm \
	lib/Win32/DBIODBC.pm
INST_MAN1DIR = ./blib/man1
INSTALLMAN1DIR = $(PREFIX)/man/man1
MAN1EXT = 1
INST_MAN3DIR = ./blib/man3
INSTALLMAN3DIR = $(PREFIX)/man/man3
MAN3EXT = 3

# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc $(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h

# Where to put things:
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

EXPORT_LIST = 

PERL_ARCHIVE = 

TO_INST_PM = DBI.pm \
	DBIXS.h \
	Driver.xst \
	dbd_xsh.h \
	dbi_sql.h \
	dbipport.h \
	lib/Bundle/DBI.pm \
	lib/DBD/ADO.pm \
	lib/DBD/ExampleP.pm \
	lib/DBD/Multiplex.pm \
	lib/DBD/NullP.pm \
	lib/DBD/Proxy.pm \
	lib/DBD/Sponge.pm \
	lib/DBI/DBD.pm \
	lib/DBI/FAQ.pm \
	lib/DBI/Format.pm \
	lib/DBI/ProxyServer.pm \
	lib/DBI/Shell.pm \
	lib/DBI/W32ODBC.pm \
	lib/Win32/DBIODBC.pm

PM_TO_BLIB = lib/DBI/W32ODBC.pm \
	$(INST_LIB)/DBI/W32ODBC.pm \
	lib/DBD/ExampleP.pm \
	$(INST_LIB)/DBD/ExampleP.pm \
	lib/DBI/FAQ.pm \
	$(INST_LIB)/DBI/FAQ.pm \
	lib/DBI/Shell.pm \
	$(INST_LIB)/DBI/Shell.pm \
	lib/DBI/ProxyServer.pm \
	$(INST_LIB)/DBI/ProxyServer.pm \
	lib/Bundle/DBI.pm \
	$(INST_LIB)/Bundle/DBI.pm \
	lib/DBD/Proxy.pm \
	$(INST_LIB)/DBD/Proxy.pm \
	lib/DBD/Multiplex.pm \
	$(INST_LIB)/DBD/Multiplex.pm \
	DBIXS.h \
	$(INST_ARCHAUTODIR)/DBIXS.h \
	dbd_xsh.h \
	$(INST_ARCHAUTODIR)/dbd_xsh.h \
	dbi_sql.h \
	$(INST_ARCHAUTODIR)/dbi_sql.h \
	lib/DBD/NullP.pm \
	$(INST_LIB)/DBD/NullP.pm \
	lib/DBD/Sponge.pm \
	$(INST_LIB)/DBD/Sponge.pm \
	lib/DBI/Format.pm \
	$(INST_LIB)/DBI/Format.pm \
	Driver.xst \
	$(INST_ARCHAUTODIR)/Driver.xst \
	lib/DBI/DBD.pm \
	$(INST_LIB)/DBI/DBD.pm \
	dbipport.h \
	$(INST_ARCHAUTODIR)/dbipport.h \
	DBI.pm \
	$(INST_LIBDIR)/DBI.pm \
	lib/Win32/DBIODBC.pm \
	$(INST_LIB)/Win32/DBIODBC.pm \
	lib/DBD/ADO.pm \
	$(INST_LIB)/DBD/ADO.pm


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /opt/perl5.004_04/lib/ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)/typemap
XSUBPPARGS = -typemap $(XSUBPPDIR)/typemap


# --- MakeMaker tools_other section:

SHELL = /bin/sh
CHMOD = chmod
CP = cp
LD = gcc
MV = mv
NOOP = $(SHELL) -c true
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1

# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e mkpath

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e eqtime

# Here we warn users that an old packlist file was found somewhere,
# and that they should call some uninstall routine
WARN_IF_OLD_PACKLIST = $(PERL) -we 'exit unless -f $$ARGV[0];' \
-e 'print "WARNING: I have found an old package in\n";' \
-e 'print "\t$$ARGV[0].\n";' \
-e 'print "Please make sure the two installations are not conflicting\n";'

UNINST=0
VERBINST=1

MOD_INSTALL = $(PERL) -I$(INST_LIB) -I$(PERL_LIB) -MExtUtils::Install \
-e "install({@ARGV},'$(VERBINST)',0,'$(UNINST)');"

DOC_INSTALL = $(PERL) -e '$$\="\n\n";' \
-e 'print "=head2 ", scalar(localtime), ": C<", shift, ">", " L<", shift, ">";' \
-e 'print "=over 4";' \
-e 'while (defined($$key = shift) and defined($$val = shift)){print "=item *";print "C<$$key: $$val>";}' \
-e 'print "=back";'

UNINSTALL =   $(PERL) -MExtUtils::Install \
-e 'uninstall($$ARGV[0],1,1); print "\nUninstall is deprecated. Please check the";' \
-e 'print " packlist above carefully.\n  There may be errors. Remove the";' \
-e 'print " appropriate files manually.\n  Sorry for the inconveniences.\n"'


# --- MakeMaker dist section:

DISTVNAME = $(DISTNAME)-$(VERSION)
TAR  = tar
TARFLAGS = cvf
ZIP  = zip
ZIPFLAGS = -r
COMPRESS = gzip -v9
SUFFIX = gz
SHAR = shar
PREOP = $(MAKE) -f Makefile.old distdir
POSTOP = @$(NOOP)
TO_UNIX = @$(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = clean distcheck disttest ci tardist


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -I/usr/local/include -I/opt/gnu/include
OPTIMIZE = -O
PERLTYPE = 
LARGE = 
SPLIT = 


# --- MakeMaker const_loadlibs section:

# DBI might depend on some other libraries:
# See ExtUtils::Liblist for details
#
LD_RUN_PATH = 


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:

# This section was generated by DBI::DBD::dbd_postamble()
DBI_INST_DIR=.
DBI_INSTARCH_DIR=$(INST_ARCHAUTODIR)
DBI_DRIVER_XST=$(DBI_INSTARCH_DIR)/Driver.xst

# The main dependancy (technically correct but probably not used)
Perl.c: Perl.xsi

# This dependancy is needed since MakeMaker uses the .xs.o rule
Perl$(OBJ_EXT): Perl.xsi

Perl.xsi: $(DBI_DRIVER_XST)
	$(PERL) -p -e "s/~DRIVER~/Perl/g" < $(DBI_DRIVER_XST) > Perl.xsi

DBI.c: Perl$(OBJ_EXT)


# --- MakeMaker pasthru section:

PASTHRU = LIB="$(LIB)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"


# --- MakeMaker c_o section:

.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

.C$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.C

.cpp$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cpp

.cxx$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cxx

.cc$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cc


# --- MakeMaker xs_c section:

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >$*.tc && $(MV) $*.tc $@


# --- MakeMaker xs_o section:

.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c


# --- MakeMaker top_targets section:

#all ::	config $(INST_PM) subdirs linkext manifypods

all :: pure_all manifypods
	@$(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	@$(NOOP)

subdirs :: $(MYEXTLIB)
	@$(NOOP)

config :: Makefile $(INST_LIBDIR)/.exists
	@$(NOOP)

config :: $(INST_ARCHAUTODIR)/.exists
	@$(NOOP)

config :: $(INST_AUTODIR)/.exists
	@$(NOOP)

config :: Version_check
	@$(NOOP)


$(INST_AUTODIR)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_AUTODIR)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_AUTODIR)/.exists

	-@$(CHMOD) 755 $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_LIBDIR)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_LIBDIR)/.exists

	-@$(CHMOD) 755 $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-@$(CHMOD) 755 $(INST_ARCHAUTODIR)

config :: $(INST_MAN1DIR)/.exists
	@$(NOOP)


$(INST_MAN1DIR)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_MAN1DIR)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_MAN1DIR)/.exists

	-@$(CHMOD) 755 $(INST_MAN1DIR)

config :: $(INST_MAN3DIR)/.exists
	@$(NOOP)


$(INST_MAN3DIR)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_MAN3DIR)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_MAN3DIR)/.exists

	-@$(CHMOD) 755 $(INST_MAN3DIR)

$(O_FILES): $(H_FILES)

help:
	perldoc ExtUtils::MakeMaker

Version_check:
	@$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		-MExtUtils::MakeMaker=Version_check \
		-e "Version_check('$(MM_VERSION)')"


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	@$(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make dynamic"
#dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT)
	@$(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP = DBI.bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): Makefile  $(INST_ARCHAUTODIR)/.exists
	@echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-MExtUtils::Mkbootstrap \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	@$(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@

$(INST_BOOT): $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
	@rm -rf $(INST_BOOT)
	-cp $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@


# --- MakeMaker dynamic_lib section:

# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = :
OTHERLDFLAGS = 
INST_DYNAMIC_DEP = 

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD) -o $@  $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) $(EXPORT_LIST)
	$(CHMOD) 755 $@


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
#static :: Makefile $(INST_STATIC) $(INST_PM)
static :: Makefile $(INST_STATIC)
	@$(NOOP)


# --- MakeMaker static_lib section:

$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
	$(RM_RF) $@
	$(AR) $(AR_STATIC_ARGS) $@ $(OBJECT) && $(RANLIB) $@
	$(CHMOD) 755 $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld



# --- MakeMaker manifypods section:
POD2MAN_EXE = /opt/perl5.004_04/bin/pod2man
POD2MAN = $(PERL) -we '%m=@ARGV;for (keys %m){' \
-e 'next if -e $$m{$$_} && -M $$m{$$_} < -M $$_ && -M $$m{$$_} < -M "Makefile";' \
-e 'print "Manifying $$m{$$_}\n";' \
-e 'system(qq[$$^X ].q["-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" $(POD2MAN_EXE) ].qq[$$_>$$m{$$_}])==0 or warn "Couldn\047t install $$m{$$_}\n";' \
-e 'chmod 0644, $$m{$$_} or warn "chmod 644 $$m{$$_}: $$!\n";}'

manifypods : dbiproxy \
	dbish \
	lib/DBI/W32ODBC.pm \
	lib/DBI/Shell.pm \
	lib/DBI/FAQ.pm \
	lib/DBI/Format.pm \
	lib/DBI/ProxyServer.pm \
	lib/Bundle/DBI.pm \
	lib/DBI/DBD.pm \
	DBI.pm \
	lib/Win32/DBIODBC.pm \
	lib/DBD/Proxy.pm \
	lib/DBD/ADO.pm \
	lib/DBD/Multiplex.pm
	@$(POD2MAN) \
	dbiproxy \
	$(INST_MAN1DIR)/dbiproxy.$(MAN1EXT) \
	dbish \
	$(INST_MAN1DIR)/dbish.$(MAN1EXT) \
	lib/DBI/W32ODBC.pm \
	$(INST_MAN3DIR)/DBI::W32ODBC.$(MAN3EXT) \
	lib/DBI/Shell.pm \
	$(INST_MAN3DIR)/DBI::Shell.$(MAN3EXT) \
	lib/DBI/FAQ.pm \
	$(INST_MAN3DIR)/DBI::FAQ.$(MAN3EXT) \
	lib/DBI/Format.pm \
	$(INST_MAN3DIR)/DBI::Format.$(MAN3EXT) \
	lib/DBI/ProxyServer.pm \
	$(INST_MAN3DIR)/DBI::ProxyServer.$(MAN3EXT) \
	lib/Bundle/DBI.pm \
	$(INST_MAN3DIR)/Bundle::DBI.$(MAN3EXT) \
	lib/DBI/DBD.pm \
	$(INST_MAN3DIR)/DBI::DBD.$(MAN3EXT) \
	DBI.pm \
	$(INST_MAN3DIR)/DBI.$(MAN3EXT) \
	lib/Win32/DBIODBC.pm \
	$(INST_MAN3DIR)/Win32::DBIODBC.$(MAN3EXT) \
	lib/DBD/Proxy.pm \
	$(INST_MAN3DIR)/DBD::Proxy.$(MAN3EXT) \
	lib/DBD/ADO.pm \
	$(INST_MAN3DIR)/DBD::ADO.$(MAN3EXT) \
	lib/DBD/Multiplex.pm \
	$(INST_MAN3DIR)/DBD::Multiplex.$(MAN3EXT)

# --- MakeMaker processPL section:

all :: dbiproxy
	@$(NOOP)

dbiproxy :: dbiproxy.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) dbiproxy.PL

all :: dbish
	@$(NOOP)

dbish :: dbish.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) dbish.PL


# --- MakeMaker installbin section:

$(INST_SCRIPT)/.exists :: /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h
	@$(MKPATH) $(INST_SCRIPT)
	@$(EQUALIZE_TIMESTAMP) /opt/perl5.004_04/lib/sun4-solaris/5.00404/CORE/perl.h $(INST_SCRIPT)/.exists

	-@$(CHMOD) 755 $(INST_SCRIPT)

EXE_FILES = dbish dbiproxy

FIXIN = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::MakeMaker \
    -e "MY->fixin(shift)"

all :: $(INST_SCRIPT)/dbiproxy $(INST_SCRIPT)/dbish
	@$(NOOP)

realclean ::
	rm -f $(INST_SCRIPT)/dbiproxy $(INST_SCRIPT)/dbish

$(INST_SCRIPT)/dbiproxy: dbiproxy Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/dbiproxy
	cp dbiproxy $(INST_SCRIPT)/dbiproxy
	$(FIXIN) $(INST_SCRIPT)/dbiproxy

$(INST_SCRIPT)/dbish: dbish Makefile $(INST_SCRIPT)/.exists
	@rm -f $(INST_SCRIPT)/dbish
	cp dbish $(INST_SCRIPT)/dbish
	$(FIXIN) $(INST_SCRIPT)/dbish


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf DBI.c Perl.c $(DISTVNAME)/ Perl.xsi dbish dbiproxy ndtest.prt ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c mon.out core so_locations pm_to_blib *~ */*~ */*/*~ *$(OBJ_EXT) *$(LIB_EXT) perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
	-mv Makefile Makefile.old $(DEV_NULL)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -f $(INST_DYNAMIC) $(INST_BOOT)
	rm -f $(INST_STATIC)
	rm -f $(INST_LIB)/DBI/W32ODBC.pm $(INST_LIB)/DBD/ExampleP.pm $(INST_LIB)/DBI/FAQ.pm $(INST_LIB)/DBI/Shell.pm $(INST_LIB)/DBI/ProxyServer.pm $(INST_LIB)/Bundle/DBI.pm $(INST_LIB)/DBD/Proxy.pm $(INST_LIB)/DBD/Multiplex.pm $(INST_ARCHAUTODIR)/DBIXS.h $(INST_ARCHAUTODIR)/dbd_xsh.h $(INST_ARCHAUTODIR)/dbi_sql.h $(INST_LIB)/DBD/NullP.pm $(INST_LIB)/DBD/Sponge.pm $(INST_LIB)/DBI/Format.pm $(INST_ARCHAUTODIR)/Driver.xst $(INST_LIB)/DBI/DBD.pm $(INST_ARCHAUTODIR)/dbipport.h $(INST_LIBDIR)/DBI.pm $(INST_LIB)/Win32/DBIODBC.pm $(INST_LIB)/DBD/ADO.pm
	rm -rf Makefile Makefile.old


# --- MakeMaker dist_basics section:

distclean :: realclean distcheck

distcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=fullcheck \
		-e fullcheck

skipcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=skipcheck \
		-e skipcheck

manifest :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=mkmanifest \
		-e mkmanifest


# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT)
	@$(PERL) -le 'print "Warning: Makefile possibly out of date with $$vf" if ' \
	    -e '-e ($$vf="$(VERSION_FROM)") and -M $$vf < -M "Makefile";'

tardist : $(DISTVNAME).tar$(SUFFIX)

zipdist : $(DISTVNAME).zip

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) \
		$(DISTVNAME).tar$(SUFFIX) > \
		$(DISTVNAME).tar$(SUFFIX)_uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker dist_dir section:

distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=manicopy,maniread \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"


# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) Makefile.PL
	cd $(DISTVNAME) && $(MAKE)
	cd $(DISTVNAME) && $(MAKE) test


# --- MakeMaker dist_ci section:

ci :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=maniread \
		-e "@all = keys %{ maniread() };" \
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \
		-e 'print("Executing $(RCS_LABEL) ...\n"); system("$(RCS_LABEL) @all");'


# --- MakeMaker install section:

install :: all pure_install doc_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_ :: install_site
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install
	@echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod

pure__install : pure_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	@$(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(INSTALLARCHLIB) \
		$(INST_BIN) $(INSTALLBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_MAN1DIR) $(INSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install ::
	@$(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLSITELIB) \
		$(INST_ARCHLIB) $(INSTALLSITEARCH) \
		$(INST_BIN) $(INSTALLBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_MAN1DIR) $(INSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

doc_perl_install ::
	@$(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLARCHLIB)/perllocal.pod

doc_site_install ::
	@$(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	@$(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	@$(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	@$(NOOP)


# --- MakeMaker perldepend section:

PERL_HDRS = \
$(PERL_INC)/EXTERN.h       $(PERL_INC)/gv.h           $(PERL_INC)/pp.h       \
$(PERL_INC)/INTERN.h       $(PERL_INC)/handy.h        $(PERL_INC)/proto.h    \
$(PERL_INC)/XSUB.h         $(PERL_INC)/hv.h           $(PERL_INC)/regcomp.h  \
$(PERL_INC)/av.h           $(PERL_INC)/keywords.h     $(PERL_INC)/regexp.h   \
$(PERL_INC)/config.h       $(PERL_INC)/mg.h           $(PERL_INC)/scope.h    \
$(PERL_INC)/cop.h          $(PERL_INC)/op.h           $(PERL_INC)/sv.h	     \
$(PERL_INC)/cv.h           $(PERL_INC)/opcode.h       $(PERL_INC)/unixish.h  \
$(PERL_INC)/dosish.h       $(PERL_INC)/patchlevel.h   $(PERL_INC)/util.h     \
$(PERL_INC)/embed.h        $(PERL_INC)/perl.h				     \
$(PERL_INC)/form.h         $(PERL_INC)/perly.h

$(OBJECT) : $(PERL_HDRS)

DBI.c Perl.c : $(XSUBPPDEPS)


# --- MakeMaker makefile section:

$(OBJECT) : $(FIRST_MAKEFILE)

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile : Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@$(MV) Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean $(DEV_NULL) || $(NOOP)
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo "==> Your Makefile has been rebuilt. <=="
	@echo "==> Please rerun the make command.  <=="
	false

# To change behavior to :: would be nice, but would break Tk b9.02
# so you find such a warning below the dist target.
#Makefile :: $(VERSION_FROM)
#	@echo "Warning: Makefile possibly out of date with $(VERSION_FROM)"


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /opt/perl5.004_04/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	@echo Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)

test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' $(TEST_FILES)
	PERL_DL_NONLAZY=1 $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERL) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)

test_ : test_dynamic

test_static :: pure_all $(MAP_TARGET)
	PERL_DL_NONLAZY=1 ./$(MAP_TARGET) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' $(TEST_FILES)
	PERL_DL_NONLAZY=1 ./$(MAP_TARGET) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)

testdb_static :: pure_all $(MAP_TARGET)
	PERL_DL_NONLAZY=1 ./$(MAP_TARGET) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)



# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" \
	"-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Install \
        -e "pm_to_blib({qw{$(PM_TO_BLIB)}},'$(INST_LIB)/auto')"
	@$(TOUCH) $@


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
