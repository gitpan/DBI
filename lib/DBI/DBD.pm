# $Id: DBD.pm,v 1.11 1998/08/09 20:48:38 timbo Exp $
#
# Copyright (c) 1997 Jonathan Leffler and Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# This module serves two purposes:
#
#	Firstly it holds documentation to assist people writing drivers.
#	Secondly it holds perl code that's used in the driver configuring
#	and building process (typically called by the drivers Makefile.PL)

=head1 NAME

DBI::DBD - DBD Driver Writer's Guide (draft)

=head1 SYNOPSIS

    perldoc DBI::FAQ

=head1 VERSION and VOLATILITY

	$Revision: 1.11 $
	$Date: 1998/08/09 20:48:38 $

This document is very much a minimal draft which will need to be revised
frequently (and extensively).

The changes will occur both because the DBI specification is changing
and hence the requirements on DBD drivers change, and because feedback
from people reading this document will suggest improvements to it.

Please read the DBI documentation first and fully, including the DBI FAQ.

This document is a patchwork of contributions from various authors.
More contributions (preferably as patches) are welcome.

=head1 DESCRIPTION

This document is primarily intended to help people writing new
database drivers for the Perl Database Interface (Perl DBI).
It may also help others interested in discovering why the internals of
a DBD driver are written the way they are.

This is a guide.  Few (if any) of the statements in it are completely
authoritative under all possible circumstances.  This means you will
need to use judgement in applying the guidelines in this document.

=head1 REGISTERING A NEW DRIVER

Before writing a new driver, it is in your interests to find out
whether there already is a driver for your database.
If there is such a driver, it would be much easier to make use of it
than to write your own.

	[...More info TBS...]

=head2 Locating drivers

The primary web-site for locating Perl software is
L<http://www.perl.com/CPAN>.
You should look under the various modules listings for the software
you are after.
Two of the main pages you should look at are:

  http://www.perl.org/CPAN/modules/by-category/07_Database_Interfaces/DBI

  http://www.perl.org/CPAN/modules/by-category/07_Database_Interfaces/DBD

The primary web-site for locating DBI software and information is
http://www.hermetica.com/technologia/DBI.

=head2 DBI Mailing Lists

There are 2 main and one auxilliary mailing lists for people working
with DBI.  The primary lists are dbi-users@fugue.com for general users
of DBI and DBD drivers, and dbi-dev@fugue.com mainly for DBD driver
writers (don't join the dbi-dev list unless you have a good reason).
The auxilliary list is dbi-announce@fugue.com for announcing new
releases of DBI or DBD drivers.

You can join these lists by accessing the web-site
L<http://www.fugue.com/dbi>.
If you have not got web access, you may send a request to
dbi-request@fugue.com, but this will be handled manually when the
people in charge find the time to deal with it.  Use the web-site.

You should also consider monitoring the comp.lang.perl newsgroups.

=head2 Registering a new driver

Before going through any official registration process, you will need
to establish that there is no driver already in the works.
You'll do that by asking the DBI mailing lists whether there is such a
driver available, or whether anybody is working on one.

	[...More info TBS...]

=head1 CREATING A NEW DRIVER USING PURE PERL

Writing a pure Perl driver is surprisingly simple. However, there are
some problems one should be aware of. The best option is of course
picking up an existing driver and carefully modifying one method
after the other. As an example we take a look at the I<DBD::File>
driver, a driver for accessing plain files as tables, which is part of
the I<DBD::CSV> package. In what follows I assume the name C<Driver>
for your new package: The least thing we have to implement are the
files C<Makefile.PL> and C<Driver.pm>.


=head2 Makefile.PL

You typically start with writing C<Makefile.PL>, a Makefile generator.
The contents of this file are described in detail in the MakeMaker
man pages, it's definitely a good idea if you start reading them.
At least you should know about the variables I<CONFIGURE>, I<DEFINED>,
I<DIR>, I<EXE_FILES>, I<INC>, I<LIBS>, I<LINKTYPE>, I<NAME>, I<OPTIMIZE>,
I<PL_FILES>, I<VERSION>, I<VERSION_FROM>, I<clean>, I<depend>, I<realclean>
from the C<ExtUtils::MakeMaker> man page: These are used in almost any
Makefile.PL. Additionally read the section on I<Overriding MakeMaker Methods>
and the descriptions of the I<distcheck>, I<disttest> and I<dist> targets:
They will definitely be usefull for you.

Of special importance for DBI drivers is the I<postamble> method from
the C<ExtUtils::MM_Unix> man page. And for Emacs users I recommend
the I<libscan> method.

Now an example, I use the word C<Driver> whereever you should insert
your drivers name:

    # -*- perl -*-

    use DBI 0.94;
    use DBI::DBD;
    use ExtUtils::MakeMaker;

    ExtUtils::MakeMaker::WriteMakefile(
        'NAME'         => 'DBD::File',
        'VERSION_FROM' => 'File.pm',
        'INC'          => $DBI_INC_DIR,
        'dist'         => { 'SUFFIX' => '.gz',
			    'COMPRESS' => 'gzip -9f' },
        'realclean'    => '*.xsi'
    );

    package MY;
    sub postamble { dbd_postamble(@_); }
    sub libscan {
	my($self, $path) = @_;
	($path =~ /\~$/) ? undef : $path;
    }

L<ExtUtils::MakeMaker(3)>. L<ExtUtils::MM_Unix(3)>. 


=head2 README file

The README file should describe the pre-requisites for the build
process, the actual build process, and how to report errors. Users
will find ways of breaking the driver build and test process which
you would never even dreamed to be possible in your nightmares. :-)
Therefore, you need to write this document defensively and precisely.
Also, it is in your interests to ensure that your tests work as widely
as possible. As always, use the README from one of the established
drivers as a basis for your own.

	[...More info TBS...]


=head2 MANIFEST

The MANIFEST will be used by the Makefile'd dist target to build the
distribution tar file that is uploaded to CPAN.


=head2 Driver.pm

The Driver.pm file defines the Perl module DBD::Driver for your driver.
It will define a package DBD::Driver along with some version information,
some variable definitions, and a function driver() which will have a more
or less standard structure.

It will also define a package DBD::Driver::dr (with methods connect(),
data_sources() and disconnect_all()), and a package DBD::Driver::db
(which will define a function prepare() etc), and a package DBD::Driver::st
with methods execute(), fetch() and the like.

The Driver.pm file will also contain the documentation specific to
DBD::Driver in the format used by perldoc.

Now let's take a closer look at an excerpt of File.pm as an example.
We ignore things that are common to any module (even non-DBI(D) modules)
or really specific for the DBD::File package.


=over 2

=item The header

  package DBD::File;

  $err = 0;		# holds error code   for DBI::err
  $errstr = "";	        # holds error string for DBI::errstr
  $sqlstate = "";       # holds SQL state for    DBI::state

These variables are used for storing error states and messages.
However, it is crucial to understand that you must not modify
them directly; instead use the I<event> method, see below.

  $drh = undef;         # holds driver handle once initialized

This is where the driver handle will be stored, once created. Note,
that you may assume, there's only one handle for your driver.

=item The driver constructor

  sub driver {
    return $drh if $drh;	# already created - return same one
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh($class, {
      'Name'    => 'File',
      'Version' => $VERSION,
      'Err'     => \$DBD::File::err,
      'Errstr'  => \$DBD::File::errstr,
      'State'   => \$DBD::File::state,
      'Attribution' => 'DBD::File by Jochen Wiedmann',
    });

    $drh;
  }

The I<driver> method is the driver handle constructor. It's a
reasonable example of how DBI implements its handles. There are three
kinds: B<driver handles> (typically stored in C<$drh>, from now on
called C<drh>), B<database handles> (from now on called C<dbh> or
C<$dbh>) and B<statement handles>, (from now on called C<sth> or
C<$sth>).

The prototype of DBI::_new_drh is

    $drh = DBI::_new_drh($class, $attr1, $attr2);

with the following arguments:

=over 4

=item I<$class>

is your drivers class, e.g., "DBD::File::dr", passed as first
argument to the I<driver> method.

=item I<$attr1>

is a hash ref to attributes like I<Name>, I<Version>, I<Err>, I<Errstr>
I<State> and I<Attributrion>. These are processed and used by DBI, you
better don't make any assumptions on them nor should you add private
attributes here.

=item I<$attr2>

This is another (optional) hash ref with your private attributes. DBI
will leave them alone.

=back

The I<DBI::new_drh> method and the I<driver> method
both return C<undef> for failure (in which case you must look at
$DBI::err and $DBI::errstr, because you have no driver handle).


=item The database handle constructor

The next lines of code look as follows:

  package DBD::Driver::dr; # ====== DRIVER ======

  $DBD::Driver::dr::imp_data_size = 0;

The database handle constructor is a driver method, thus we have
to change the namespace.

  sub connect {
    my($drh, $dbname, $user, $auth, $attr)= @_;

    # Some database specific verifications, default settings
    # and the like following here. This should only include
    # syntax checks or similar stuff where it's legal to
    # 'die' in case of errors.

    # create a 'blank' dbh (call superclass constructor)
    my $dbh = DBI::_new_dbh($drh, {
      'Name' => $dbname,
      'USER' => $user,
      'CURRENT_USER' => $user,
    });

    # Process attributes from the DSN; we assume ODBC syntax
    # here, that is, the DSN looks like var1=val1;...;varN=valN

    my $var;
    foreach $var (split(/;/, $dbname)) {
      if ($var =~ /(.*?)=(,*)/) {
	# Not !!! $dbh->{$var} = $val;
	$dbh->STORE($var, $val);
      }
    }
    $dbh;
  }

This is mostly the same as in the I<driver handle constructor> above.
The arguments are described in the DBI man page. See L<DBI(3)>.
The constructor is called, returning a database handle. The constructors
prototype is

    $dbh = DBI::_new_dbh($drh, $attr1, $attr2);

with the same arguments as in the I<driver handle constructor>, the
exception being C<$class> replaced by C<$drh>.

Note the use of the I<STORE> method for setting the dbh attributes:
Outside the driver sources you would instead do a

    $dbh->{$var} = $val;

However, this won't work in all cases, because DBI handles for reasons
that are far beyond the scope of this document. (To be honest, I,
Jochen Wiedmann, still don't understand all the things Tim does in
his XS sources. ;-)


=item Other driver handle methods

may follow here. In particular you should consider a I<data_sources>
method, and a (possibly empty) I<disconnect_all> method. See L<DBI(3)>.


=item The statement handle constructor

There's nothing much new in the statement handle constructor.

  package DBD::Driver::db; # ====== DATABASE ======

  $DBD::Driver::db::imp_data_size = 0;

  sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth
	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Setup module specific data
	$sth->STORE('driver_params', []);
	$sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//));

	$sth;
  }

This is still the same: Check the arguments and call the super class
constructor I<DBI::_new_sth>. Note the prefix I<driver_> in the
attribute names: It is strongly recommended that your private attributes
are lowercased and use such a prefix.

Note that we parse the statement here in order to setup the attribute
I<NUM_OF_PARAMS>. We could as well do this in the I<execute> method
below, the DBI specs explicitly allow to defer this. However, one
could not call I<bind_param> in that case.


=item Transaction handling

Pure Perl drivers will rarely support transactions. Thus you're I<commit>
and I<rollback> methods will typically be quite simple:

  sub commit {
    my($dbh) = @_;
    if ($dbh->FETCH('Warn')) {
      warn("Commit  ineffective while AutoCommit is on");
    }
    1;
  }

  sub rollback {
    my($dbh) = @_;
    if ($dbh->FETCH('Warn')) {
      warn("Commit  ineffective while AutoCommit is on");
    }
    0;
  }


=item The STORE and FETCH methods

These methods (that we have already used, see above) are called for
you, whenever the user does a

    $dbh->{$attr} = $val;

or, respectively,

    $val = $dbh->{$attr};

See L<perltie(1)> for details on tied hash refs to understand why these
methods are required.

It is a DBI specific thing, that your methods are rarely called: In fact
DBI catches most attributes for you, in particular attributes like
I<RaiseError> or I<PrintError>. All you have to do is handling your
driver's private methods. A good example might look like this:

  sub STORE {
    my($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
      # AutoCommit is the only standard attribute whe have to
      # consider.
      if (!$val) { die "Can't disable AutoCommit"; }
      return 1;
    }
    if ($attr =~ /^driver_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      $dbh->{$attr} = $val; # Yes, we are allowed to do this,
      return 1;             # but only for our private attributes
    }
    # Else pass up to DBI to handle
    $dbh->DBD::_::db::STORE($attr, $val);
  }

  sub FETCH {
    my($dbh, $attr) = @_;
    if ($attr eq 'AutoCommit') { return 1; }
    if ($attr =~ /^driver_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      return $dbh->{$attr}; # Yes, we are allowed to do this,
                            # but only for our private attributes
    }
    # Else pass up to DBI to handle
    $dbh->DBD::_::st::FETCH($attr);
  }


=item Other database handle methods

may follow here. In particular you should consider a (possibly empty)
I<disconnect> method, a I<quote> method (if DBI's default isn't good
for you).


=item The execute method

This is perhaps the most difficult method because we have to consider
parameter bindings here. We present a simplified implementation by
using the I<driver_params> attribute from above:

  package DBD::Driver::st;

  $DBD::Driver::st::imp_data_size = 0;

  sub bind_param {
    my($sth, $pNum, $val, $attr) = @_;
    my $params = $sth->FETCH('driver_params');
    if (!$attr  ||  ($attr != DBI::SQL_INTEGER  &&
		     $attr != DBI::SQL_DECIMAL  &&
		     ...)) {
	my $dbh = $sth->{Database};
	$val = $dbh->quote($sth);
    }
    $params->[$pNum-1] = $val;
    1;
  }

  sub execute {
    my($sth, @bind_values) = @_;
    my $params = (@bind_values) ?
	\@bind_values : $sth->FETCH('driver_params');
    my $numParam = $sth->FETCH('NUM_OF_PARAMS');
    my $statement = $sth->{'Statement'};
    for (my $i = 0;  $i < $numParam;  $i++) {
	$statement =~ s/?/$params->[$i]/e;
    }
    # Do anything ... we assume that an array ref of rows is
    # created and store it:
    $sth->{'driver_data'} = $data;
    $sth->{'driver_rows'} = @$data;
    $sth->STORE('NUM_OF_FIELDS') = $numFields;
    @$data || '0E0';
  }

Things you should note here: We setup the NUM_OF_FIELDS attribute
here, because this is essential for I<bind_columns> to work. And
we use attribute I<$sth->{'Statement'}> which we have created
within I<prepare>. The attribute I<$sth->{'Database'}>, which is
nothing else than the I<dbh>, was automatically created by DBI.

Finally note that we return the string '0E0' instead of the number
0, so that

  if (!$sth->execute()) { die $sth->errstr }

works.


=item Fetching data

We need not implement the methods I<fetchrow_array>, I<fetchall_arrayref>,
... because these are already part of DBI. All we need is the method
I<fetchrow_arrayref>:

  sub fetchrow_arrayref {
    my($sth) = @_;
    my $data = $sth->FETCH('driver_data');
    my $row = shift @$data;
    if (!$row) { return undef; }
    if ($sth->FETCH('ChopBlanks')) {
	map { $_ =~ s/\s+$//; } @$row;
    }
    $sth->_set_fbav($row);
  }
  *fetch = \&fetchrow_arrayref;

  sub rows { my($sth) = @_; $sth->FETCH('driver_rows'); }

Note the use of the method I<_set_fbav>: This is required so that
I<bind_col> and I<bind_columns> work.

Fixing the broken implementation for correct handling of quoted
question marks is left as an exercise to the reader. :-)


=item Statement attributes

The main difference between dbh and sth attributes is, that you
should implement a lot of attributes here that are required by
the DBI: For example I<NAME>, I<NULLABLE>, I<TYPE>, ...
Besides that the STORE and FETCH methods are mainly the same
as above for dbh's.


=item Other statement methods

Finally you should implement a (perhaps trivial) I<finish> method and
perhaps some other methods that are not part of the DBI specs, in
particular make metadata available. Considering Tim's last articles
do yourself a favour and follow the ODBC driver.


=back


=head2 Tests

The test process should conform as closely as possibly to the Perl
standard test harness.

In particular, most of the tests should be run in the t sub-directory,
and should simply produce an 'ok' when run under 'make test'.
For details on how this is done, see the Camel book and the section in
Chapter 7, "The Standard Perl Library" on Test::Harness.

The tests may need to adapt to the type of database which is being
used for testing, and to the privileges of the user testing the
driver.

The DBD::Informix test code has to adapt in a number of places to the
type of database to which it is connected as different Informix
databases have different capabilities.

	[...More info TBS...]


=head1 CREATING A NEW DRIVER USING C/XS

Creating a new C/XS driver from scratch will always be a daunting task.
You can and should greatly simplify your task by taking a good
reference driver implementation and modifying that to match the
database product for which you are writing a driver.

The de facto reference driver has been the one for DBD::Oracle, written
by Tim Bunce who is also the author of the DBI package. The DBD::Oracle
module is a good example of a driver implemented around a C-level API.

Nowadays it it seems better to base on DBD::ODBC, another driver
maintained by Tim, because it offers a lot of metadata and seems
to become the guideline for the future development.

The DBD::Informix driver is a good reference for a driver implemented
using 'embedded SQL'.

	[...More info TBS...]

=head1 REQUIREMENTS ON A DRIVER

T.B.S.

=head1 CODE TO BE WRITTEN

A minimal driver will contain 7 files plus some tests. Assuming that your
driver is called DBD::Driver, these files are:

=over 4

=item Driver.pm

=item Driver.xs

=item Driver.h

=item dbdimp.h

=item dbdimp.c

=item Makefile.PL

=item README

=item MANIFEST

=back


=head2 Driver.pm

The Driver.pm file is the same as for Pure Perl modules, see above.
However, there are some subtile differences:

=over 8

=item *

The variables $DBD::File::dr|db|st::imp_data_size are not defined
here, but in the XS code, because they declare the size of certain
C structures.

=item *

Some methods are moved to the XS code, in particular I<prepare>,
I<execute>, I<disconnect>, I<disconnect_all> and the STORE and
FETCH methods.

=item *

Other methods are still part of C<Driver.pm>, but have callbacks in
the XS code.

=back


Now let's take a closer look at an excerpt of Oracle.pm as an example.
We ignore things that are already discussed for Pure Perl drivers or
really Oracle specific.

=over 2

=item The database handle constructor

  sub connect {
	my($drh, $dbname, $user, $auth)= @_;

	# Some database specific verifications, default settings
	# and the like following here. This should only include
	# syntax checks or similar stuff where it's legal to
	# 'die' in case of errors.

	# create a 'blank' dbh (call superclass constructor)
	my $dbh = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 'CURRENT_USER' => $user,
	    });

	# Call Oracle OCI orlon func in Oracle.xs file
	# and populate internal handle data.
	DBD::Oracle::db::_login($dbh, $dbname, $user, $auth)
	    or return undef;

	$dbh;
    }

This is mostly the same as in the Pure Perl case, the exception being
the use of the private I<_login> callback: This will really connect to
the database. It is implemented in Driver.xst (you should not implement
it) and calls I<dbd_db_login> from I<dbdimp.c>. See below for details.

(XXX, Tim: No check for 'undef' befor calling _login? There's no check
in Oracle.xs, either)

=item The statement handle constructor

There's nothing much new in the statement handle constructor. Like
the I<connect> method it has a C callback:

  package DBD::Oracle::db; # ====== DATABASE ======
  use strict;

  sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth
	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call Oracle OCI oparse func in Oracle.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::Oracle::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
  }

=back


=head2 Driver.xs

Driver.xs should look something like this:

  #include "Driver.h"

  DBISTATE_DECLARE;

  INCLUDE: Driver.xsi

  MODULE = DBD::Driver    PACKAGE = DBD::Driver::db

  /* Non-standard dbh XS methods following here, if any.       */
  /* Currently this includes things like _list_tables from     */
  /* DBD::mSQL and DBD::mysql.                                 */

  MODULE = DBD::Driver    PACKAGE = DBD::Driver::st

  /* Non-standard sth XS methods following here, if any.       */
  /* In particular this includes things like _list_fields from */
  /* DBD::mSQL and DBD::mysql for accessing metadata.          */

Note especially the include of I<Driver.xsi> here: DBI inserts stub
functions for almost all private methods here which will typically
do much work for you. Wherever you really have to implement something,
it will call a private function in I<dbdimp.c>: This is what you have
to implement.


=head2 Driver.h

Driver.h should look like this:

  #define NEED_DBIXS_VERSION 9

  #include <DBIXS.h>      /* installed by the DBI module  */

  #include "dbdimp.h"

  #include <dbd_xsh.h>     /* installed by the DBI module  */


=head2 Implementation header dbdimp.h

This header file has two jobs: First it defines data structures for your
private part of the handles. Second it defines macros that rename the
generic names like I<dbd_db_login> to database specific names like
I<ora_db_login>. This avoids name clashes and enables use of different
drivers when you work with a statically linked perl.

People liked to just pick Oracle's dbdimp.c and use the same names,
structures and types. I strongly recommend against that: At first
glance this saves time, but your implementation will be less readable.
It was just a hell when I had to separate DBI specific parts, Oracle
specific parts, mSQL specific parts and mysql specific parts in
DBD::mysql's I<dbdimp.h> and I<dbdimp.c>. (DBD::mysql was a port of
DBD::mSQL which was based on DBD::Oracle.) This part of the driver
is I<your exclusive part>. Rewrite it from scratch, so it will be
clean and short, in other words: A better piece of code. (Of course
have an eye at other people's work.)

   struct imp_drh_st {
        dbih_drc_t com;		/* MUST be first element in structure	*/

       /* Insert your driver handle attributes here */
   };

   struct imp_dbh_st {
       dbih_dbc_t com;		/* MUST be first element in structure	*/

       /* Insert your database handle attributes here */
   };

   struct imp_sth_st {
       dbih_stc_t com;		/* MUST be first element in structure	*/

       /* Insert your statement handle attributes here */
   };

   /*  Rename functions for avoiding name clashes; prototypes are  */
   /*  in dbd_xst.h                                                */
   #define dbd_init	        ora_init
   #define dbd_db_login	    ora_db_login
   #define dbd_db_do        ora_db_do
   ... many more here ...

This structures implement your private part of the handles. You I<have>
to use the name I<imp_dbh_dr|db|st> and the first field I<must> be of
type I<dbih_drc|dbc|stc_t>. You should never access this fields directly,
except of using the I<DBIc_xxx> macros below.


=head2 Implementation source dbdimp.c

This is the main implementation file. I will drop a short note on any
function here that's used in the I<Driver.xsi> template and thus B<has>
to be implemented. Of course you can add private or better static
functions here.

Note that most people are still using Kernighan & Ritchie syntax here.
I personally don't like this and especially in this documentation it
cannot be of harm, so let's use ANSI. Finally Tim Bunce has announced
interest in moving the DBI sources to ANSI as well.

=over 2

=item Initialization

    #include "Driver.h"

    DBISTATE_DECLARE;

    void dbd_init(dbistate_t* dbistate) {
        DBIS = dbistate;  /*  Initialize the DBI macros  */
    }

dbd_init will be called when your driver is first loaded. These
statements are needed for use of the DBI macros. They will include your
private header file I<dbdimp.h> in turn.

=item do_error

The do_error method will be called to store error codes and messages
in either handle:

    void do_error(SV* h, int rc, char* what) {

Note that I<h> is a generic handle, may it be a driver handle, a
database or a statement handle.

        D_imp_xxh(h);

This macro will declare and initialize a variable I<imp_xxh> with
a pointer to your private handle pointer. You may cast this to
to I<imp_drh_t>, I<imp_dbh_t> or I<imp_sth_t>.

        SV *errstr = DBIc_ERRSTR(imp_xxh);
        sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early	*/
        sv_setpv(errstr, what);
        DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);

Note the use of the macros DBIc_ERRSTR and DBIc_ERR for accessing the
handles error string and error code.

The macro DBIh_EVENT2 will ensure that the attributes I<RaiseError>
and I<PrintError> work: That's all what you have to deal with them. :-)

        if (dbis->debug >= 2)
	      fprintf(DBILOGFP, "%s error %d recorded: %s\n",
		    what, rc, SvPV(errstr,na));

That's the first time we see how debug/trace logging works within a DBI
driver.  Make use of this as often as you can!

=item dbd_db_login

    int dbd_db_login(SV* dbh, imp_dbh_t* imp_dbh, char* dbname,
                     char* user, char* auth) {

This function will really connect to the database. The argument I<dbh>
is the database handle. I<imp_dbh> is the pointer to the handles private
data, as is I<imp_xxx> in I<do_error> above. The arguments I<dsn>,
I<user> and I<auth> correspond to the arguments of the driver handles
I<connect> method.

You will quite often use database specific attributes here, that are
specified in the DSN. I recommend you parse the DSN within the
I<connect> method and pass them as handle attributes to I<dbd_db_login>.
Here's how you fetch them, as an example we use I<hostname> and I<port>
attributes:

  SV* imp_data = DBIc_IMP_DATA(dbh);
  HV* hv;
  SV** svp;
  char* hostname;
  char* port;

  if (!SvTRUE(imp_data)  ||  !SvROK(imp_data)  ||
	SvTYPE(hv = (HV*) SvRV(imp_data)) != SVt_PVHV) {
	croak("Implementation dependent data invalid: Not a hash ref.\n");
  }
  if ((svp = hv_fetch(hv, "hostname", strlen("hostname"), FALSE)) &&
        SvTRUE(*svp)) {
	hostname = SvPV(*svp, na);
  } else {
	hostname = "localhost";
  }
  if ((svp = hv_fetch(hv, "port", strlen("port"), FALSE))  &&
        SvTRUE(*svp)) {
	port = SvPV(*svp, na);  /*  May be a service name  */
  } else {
        port = DEFAULT_PORT;
  }

Now you should really connect to the database. If you are successfull
(or even if you fail, but you have allocated some resources, you should
use the following macros:

  DBIc_on(imp_dbh, DBIcf_ACTIVE);
  DBIc_on(imp_dbh, DBIcf_IMPSET);

The former tells DBI that the handle has to I<disconnect>. The latter
declares that the handle has allocated resources and the private
destructor (dbd_db_destroy, see below) has to be called.

The dbd_db_login method should return TRUE for success, FALSE otherwise.


=item dbd_db_commit

=item dbd_db_rollback

    int dbd_db_commit(SV* dbh, imp_dbh_t* imp_dbh);
    int dbd_db_rollback(SV* dbh, imp_dbh_t* imp_dbh);

These are used for commit and rollback. They should return TRUE for
success, FALSE for error.

The arguments I<dbh> and I<imp_dbh> are like above, I will omit
describing them in what follows, as they appear always.


=item dbd_db_disconnect

This is your private part of the I<disconnect> method. Any dbh with
the I<ACTIVE> flag on must be disconnected. (Note that you have to set
it in I<dbd_db_connect> above.)

    int dbd_db_disconnect(SV* dbh, imp_dbh_t* imp_dbh);

The database handle will return TRUE for success, FALSE otherwise.
In any case it should do a

    DBIc_off(imp_dbh, DBIcf_ACTIVE);

before returning so DBI knows that I<dbd_db_disconnect> was executed.


=item dbd_db_discon_all

    int dbd_discon_all (SV *drh, imp_drh_t *imp_drh) {

This function may be called at shutdown time. Currently it does just
nothing, best is you just copy code from the Oracle driver. (XXX, Tim:
Comments?)

You guess what the return codes are? (Hint: See the last functions
above ... :-)


=item dbd_db_destroy

This is your private part of the database handle destructor. Any dbh with
the I<IMPSET> flag on must be destroyed, so that you can safely free
resources. (Note that you have to set it in I<dbd_db_connect> above.)

    void dbd_db_destroy(SV* dbh, imp_dbh_t* imp_dbh) {
        if (DBIc_is(imp_dbh, DBIcf_ACTIVE))  /*  Never hurts  */
            dbd_db_disconnect(dbh, imp_dbh);
        DBIc_off(imp_dbh, DBIcf_IMPSET);
    }

Before returning the function must switch IMPSET to off, so DBI knows
that the destructor was called.


=item dbd_db_STORE_attrib

This function handles

     $dbh->{$key} = $value;

its prototype is

    int dbd_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv,
                            SV* valuesv);

You do not handle all attributes, in contrary you should not handle
DBI attributes here: Leave this to DBI. (There's one exception,
I<AutoCommit>, which you should care about.)

The return value is TRUE, if you have handled the attribute or FALSE
otherwise. If you are handling an attribute and something fails, you
should call I<do_error>, so DBI can raise exceptions, if desired.
If I<do_error> returns, however, you have a problem: The user will
never know about the error, because he typically will not check
C<$dbh-E<gt>errstr>.

I cannot recommend a general way of going on, if I<do_error> returns,
but there are examples where even the DBI specification expects that
you croak(). (See the I<AutoCommit> method in L<DBI(3)>.)

If you have to store attributes, you should either use your private
data structure imp_xxx or use the private imp_data. The former is
easier for C values like integers or pointers, the latter has
advantages for Perl values like strings or more complex structures:
Because its stored in a Perl hash ref, Perl itself will do the
resource tracking for you.


=item dbd_db_FETCH_attrib

This is the counterpart of dbd_db_STORE_attrib, needed for

    $value = $dbh->{$key};

Its prototype is:

    SV* dbd_db_FETCH_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv) {

Unlike all previous methods this returns an SV with the value. Note
that you have to execute sv_2mortal, if you return a nonconstant
value. (Constant values are C<&sv_undef>, C<&sv_no> and C<&sv_yes>.)

Note, that DBI implements a caching algorithm for attribute values.
If you think, that an attribute may be fetched, you store it in the
dbh itself:

    if (cacheit) /* cache value for later DBI 'quick' fetch? */
        hv_store((HV*)SvRV(dbh), key, kl, cachesv, 0);


=item dbd_st_prepare

This is the private part of the I<prepare> method. Note that you
B<must not> really execute the statement here. You may, for example,
preparse the statement or do similar things.

    int dbd_st_prepare(SV* sth, imp_sth_t* imp_sth, char* statement,
		       SV* attribs);

A typical, simple possibility is just to store the statement in the
imp_data hash ref and use it in dbd_st_execute. If you can, you may
already setup attributes like NUM_OF_FIELDS, NAME, ... here, but DBI
doesn't expect that. However, if you do, document it.

In any case you should set the IMPSET flag, as you did in
I<dbd_db_connect> above:

   DBIc_on(imp_sth, DBIcf_ACTIVE);


=item dbd_st_execute

This is where a statement will really be executed.

   int dbd_st_execute(SV* sth, imp_sth_t* imp_sth);

Note, that you must be aware, that a statement may be executed repeatedly.
Even worse, you should not expect, that I<finish> will be called between
two executions.

If your driver supports binding of parameters (he should!), but the
database doesn't, you must probably do it here. This can be done as
follows:

      char* statement = dbd_st_get_statement(sth, imp_sth);
          /*  Its your drivers task to implement this function.  It      */
          /*  must restore the statement passed to preparse.            */
          /*  See use of imp_data above for an example of how to do     */
          /* this.                                                     */
      int numParam = DBIc_NUM_PARAMS(imp_sth);
      int i;

      for (i = 0;  i < numParam;  i++) {
	  char* value = dbd_db_get_param(sth, imp_sth, i);
	      /*  Its your drivers task to implement dbd_db_get_param,  */
              /*  it must be setup as a counterpart of dbd_bind_ph.     */
          /*  Look for '?' and replace it with 'value'.  Difficult       */
          /*  task, note that you may have question marks inside        */
          /*  quotes and the like ...  :-(                               */
          /*  See DBD::mysql for an example. (Don't look too deep into  */
          /*  the example, you will notice where I was lazy ...)        */
      }

The next thing is you really execute the statement. Note that you must
prepare the attributes NUM_OF_FIELDS, NAME, ... when the statement is
successfully executed: They may be used even before a potential
I<fetchrow>. In particular you have to tell DBI the number of fields,
that the statement has, because it will be used by DBI internally.
Thus the function will typically ends with:

    DBIc_NUM_FIELDS(imp_sth) = statementHasResult ? numFields : 0;
    DBIc_on(imp_sth, DBIcf_ACTIVE);

Note that setting ACTIVE to on will force calling the I<finish> method.
See I<dbd_st_preparse> and I<dbd_db_connect> above for more explanations.


=item dbd_st_fetch

This function fetches a row of data. The row is stored in in an array,
of SV's that DBI prepares for you. This has two advantages: It is fast
(you even reuse the SV's, so they don't have to be created after the
first fetchrow) and it guarantees, that DBI handles I<bind_cols> for
you.

What you do is the following:

    AV* av = DBIS->get_fbav(imp_sth);
    int numFields = DBIc_NUM_FIELDS(imp_sth); /* Correct, if NUM_FIELDS
        is constant for this statement. There are drivers where this is
        not the case! */
    int i;
    int chopBlanks = DBIc_is(imp_sth, DBIcf_ChopBlanks);

    for (i = 0;  i < numFields;  i++) {
        SV* sv = fetch_a_field(sth, imp_sth, i);
        if (chopBlanks) {
            /*  Remove white space from beginning and end of sv  */
        }
        sv_setsv(AvARRAY(av)[i], sv); /* Note: (re)use! */
    }
    return av;

NULL values must be returned as undef: use SvOK_off(sv);

The function returns the AV prepared by DBI for success or C<Nullav>
otherwise.

=item dbd_st_finish

This function is called if the user wishes to indicate that he won't
fetch any more rows. (XXX, Tim: How about NUM_FIELDS and NAME after
this point?) It will only be called by DBI, if the driver has set
ACTIVE to on for the sth.

    int dbd_st_finish(SV* sth, imp_sth_t* imp_sth) {
        DBIc_ACTIVE_off(imp_sth);
        return 1;
    }

The function returns TRUE for success, FALSE otherwise.

=item dbd_st_destroy

This function is the private part of the statement handle destructor.

    void dbd_st_destroy(SV* sth, imp_sth_t* imp_sth);
        if (DBIc_is(imp_sth, DBIcf_ACTIVE)) /* Never hurts */
	    dbd_st_finish(sth, imp_sth);
        DBIc_IMPSET_off(imp_sth); /* let DBI know we've done it   */
   }

=item dbd_st_STORE_attrib

=item dbd_st_FETCH_attrib

These functions correspond to dbd_db_STORE|FETCH attrib above, except
that they are for statement handles. See above.

    int dbd_st_STORE_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv,
                            SV* valuesv);
    SV* dbd_st_FETCH_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv);

=item dbd_st_blob_read

I don't know the exact meaning of this function. (XXX, Tim.)

    int dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field,
			  long offset, long len, SV *destrv,
			  long destoffset);

=item dbd_bind_ph

This function is internally used by the I<bind_col> method.

    int dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param,
		     SV *value, IV sql_type, SV *attribs,
		     int is_inout, IV maxlen);

The I<param> argument holds an IV with the parameter number. (1, 2, ...)
The I<value> argument is the parameter value and I<sql_type> is its type.

You should croak, when I<is_inout> is TRUE and ignore I<maxlen>.

In drivers of simple databases the function will, for example, store
the value in a parameter array and use it later in I<dbd_st_execute>.
See the I<DBD::mysql> driver for an example.


=back

=head2 Makefile.PL

This is exactly as in the Pure Perl case. To be honest, the above
Makefile.PL contains some things that are superfluos for Pure Perl
drivers. :-)


=head1 METHODS WHICH DO NOT NEED TO BE WRITTEN

The DBI code implements the majority of the methods which are
accessed using the notation DBI->function(), the only exceptions being
DBI->connect() and DBI->data_sources() which require support from the
driver.

=over 4

=item DBI->available_drivers()

=item DBI->neat_list()

=item DBI->neat()

=item DBI->dump_results()

=item DBI->func()

=back

The DBI code implements the following documented driver, database and
statement functions which do not need to be written by the DBD driver
writer.

=over 4

=item $dbh->do()

The default implementation of this function prepares, executes and
destroys the statement.  This should be replaced if there is a better
way to implement this, such as EXECUTE IMMEDIATE.

=item $h->errstr()

=item $h->err()

=item $h->state()

=item $h->trace()

The DBD driver does not need to worry about this routine at all.

=item $h->{ChopBlanks}

This attribute needs to be honured during fetch operations, but does
not need to be handled by the attribute handling code.

=item $h->{RaiseError}

The DBD driver does not need to worry about this attribute at all.

=item $h->{PrintError}

The DBD driver does not need to worry about this attribute at all.

=item $sth->bind_col()

Assuming the driver uses the DBIS->get_fbav() function (C drivers,
see below), or the $sth->_set_fbav($data) method (Perl drivers)
the driver does not need to do anything about this routine.

=item $sth->bind_columns()

Regardless of whether the driver uses DBIS->get_fbav(), the driver
does not need to do anything about this routine as it simply
iteratively calls $sth->bind_col().

=back

The DBI code implements a default implementation of the following
functions which do not need to be written by the DBD driver writer
unless the default implementation is incorrect for the Driver.

=over 4

=item $dbh->quote()

This should only be written if the database does not accept the ANSI
SQL standard for quoting strings, with the string enclosed in single
quotes and any embedded single quotes replaced by two consecutive
single quotes.

=item $dbh->ping()

This should only be written if there is a simple, efficient way to determine
whether the connection to the database is still alive.
Many drivers will accept the default, do-nothing implementation.

=back


=head1 WRITING AN EMULATION LAYER FOR AN OLD PERL INTERFACE

Study Oraperl.pm (supplied with DBD::Oracle) and Ingperl.pm (supplied
with DBD::Ingres) and the corresponding dbdimp.c files for ideas.


=head2 Setting emulation perl variables

For example, ingperl has a $sql_rowcount variable. Rather than try
to manually update this in Ingperl.pm it can be done faster in C code.
In dbd_init():

  sql_rowcount = perl_get_sv("Ingperl::sql_rowcount", GV_ADDMULTI);

In the relevant places do:

  if (DBIc_COMPAT(imp_sth))	/* only do this for compatibility mode handles */
      sv_setiv(sql_rowcount, the_row_count);


=head1 OTHER MISCELLANEOUS INFORMATION

Many details still T.B.S.

=head2 The imp_xyz_t types

Any handle has a corresponding C structure filled with private data.
Some of this data is reserved for use by DBI (except for using the
DBIc macros below), some is for you. See the description of the
I<dbdimp.h> file above for examples. The most functions in dbdimp.c
are passed both the handle C<xyz> and a pointer to C<imp_xyz>. In
rare cases, however, you may use the following macros:

=over 2

=item D_imp_dbh(dbh)

Given a function argument I<dbh>, declare a variable I<imp_dbh> and
initialize it with a pointer to the handles private data. Note: This
must be a part of the function header, because it declares a variable.

=item D_imp_sth(sth)

Likewise for statement handles.

=item D_imp_xxx(h)

Given any handle, declare a variable I<imp_xxx> and initialize it
with a pointer to the handles private data. It is safe, for example,
to cast I<imp_xxx> to C<imp_dbh_t*>, if

    sv_derived_from(h, "DBI::db")

is TRUE.

=item D_imp_sth_from_dbh

Given a statement handle sth and its private data imp_sth (XXX, Tim:
One of them sufficient?), declare a variable I<imp_dbh> and initialize
it with a pointer to the database handles private data.

=back


=head2 Using DBIc_IMPSET_on

The driver code which initializes a handle should use DBIc_IMPSET_on()
as soon as its state is such that the cleanup code must be called.
When this happens is determined by your driver code.

Failure to call this can lead to corruption of data structures.
For example, DBD::Informix maintains a linked list of database handles
in the driver, and within each handle, a linked list of statements.
Once a statement is added to the linked list, it is crucial that it is
cleaned up (removed from the list).
When DBIc_IMPSET_on() was being called too late, it was able to cause
all sorts of problems.


=head2 Using DBIc_is(), DBIc_on() and DBIc_off()

Once upon a long time ago, the only way of handling the attributes
such as DBIcf_IMPSET, DBIcf_WARN, DBIcf_COMPAT etc was through macros
such as:

    DBIc_IMPSET     DBIc_IMPSET_on      DBIc_IMPSET_off
    DBIc_WARN       DBIc_WARN_on        DBIc_WARN_off
    DBIc_COMPAT     DBIc_COMPAT_on      DBIc_COMPAT_off

Each of these took an imp_xyz pointer as an argument.

Since then, new attributes have been added such as ChopBlanks,
RaiseError and PrintError, and these do not have the full set of
macros.
The approved method for handling these is now the triplet of macros:

	DBIc_is(imp, flag)
	DBIc_has(imp, flag)    an alias for DBIc_is
	DBIc_on(imp, flag)
	DBIc_off(imp, flag)

Consequently, the DBIc_IMPSET family of macros is now deprecated and
new drivers should avoid using them, even though the older drivers
will probably continue to do so for quite a while yet.


=head2 Using DBIS->get_fbav()

The $sth->bind_col() and $sth->bind_columns() documented in the DBI
specification do not have to be implemented by the driver writer
becuase DBI takes care of the details for you.
However, the key to ensuring that bound columns work is to call the
function DBIS->get_fbav() in the code which fetches a row of data.
This returns an AV, and each element of the AV contains the SV which
should be set to contain the returned data.

The above is for C drivers only. The Perl equivalent is the
$sth->_set_fbav($data) method, as described in the part on Pure
Perl drivers.


=head1 SUBCLASSING DBI DRIVERS

This is definitely an open subject. It can be done, as demonstrated by
the I<DBD::File> driver, but it is not as simple as one might think.

The main problem is that the dbh's and sth's that your I<connect> and
I<prepare> methods return are not instances of your I<DBD::Driver::db>
or I<DBD::Driver::st> packages, they are not even derived from it.
Instead they are instances of the I<DBI::db> or I<DBI::st> classes or
a derived subclass. Thus, if you write a method I<mymethod> and do a

    $dbh->mymethod()

then the autoloader will search for that method in the package I<DBI::db>.
Of course you can instead to a

    $dbh->func('mymethod')

and that will indeed work, even if I<mymethod> is inherited, but not
without additional work. Setting C<@ISA> is not sufficient.


=head2 Overwriting methods

The first problem is, that the I<connect> method has no idea of
subclasses. For example, you cannot implement base class and subclass
in the same file: The I<install_driver> method wants to do a

    require DBD::Driver;

In particular, your subclass B<has> to be a separate driver, from
the view of DBI, and you cannot share driver handles.

Of course that's not much of a problem. You should even be able
to inherit the base classes I<connect> method. But you cannot
simply overwrite the method, unless you do something like this,
quoted from I<DBD::CSV>:

  sub connect ($$;$$$) {
    my($drh, $dbname, $user, $auth, $attr) = @_;

    my $this = $drh->DBD::File::dr::connect($dbname, $user, $auth, $attr);
    if (!exists($this->{csv_tables})) {
      $this->{csv_tables} = {};
    }

    $this;
  }

Note that we cannot do a

    $srh->SUPER::connect($dbname, $user, $auth, $attr);

as we would usually do in a an OO environment, because $drh is an instance
of I<DBI::dr>. And note, that the I<connect> method of I<DBD::File> is
able to handle subclass attributes. See the description of Pure Perl
drivers above.

It is essential that you always call superclass method in the above
manner. However, that should do.


=head2 Attribute handling

Fortunately the DBI specs allow a simple, but still performant way of
handling attributes. The idea is based on the convention that any
driver uses a prefix I<driver_> for its private methods. Thus it's
always clear whether to pass attributes to the super class or not.
For example, consider this STORE method from the I<DBD::CSV> class:

    sub STORE {
	my($dbh, $attr, $val) = @_;
	if ($attr !~ /^driver_/) {
	    return $dbh->DBD::File::db::STORE($attr, $val);
	}
	if ($attr eq 'driver_foo') {
	...
    }


=head1 ACKNOWLEDGEMENTS

Tim Bunce - for writing DBI and managing the DBI specification and the
DBD::Oracle driver.


=head1 AUTHORS

Jonathan Leffler <johnl@informix.com>,
Jochen Wiedmann <joe@ispsoft.de>,
and Tim Bunce.

=cut


package DBI::DBD;
use Exporter ();
use Config;
use Carp;
use DBI ();
BEGIN { if ($^O eq 'VMS') {
    require vmsish;
    import  vmsish;
    require VMS::Filespec;
    import  VMS::Filespec;
}}

@ISA = qw(Exporter);

$DBI::DBD::VERSION = $DBI::VERSION;

@EXPORT = qw(
	dbd_dbi_dir dbd_dbi_arch_dir
	dbd_edit_mm_attribs dbd_postamble
);

use strict;


sub dbd_edit_mm_attribs {
	my %a = @_;

	return %a;
}


sub dbd_dbi_dir {
	my $dbidir = $INC{'DBI.pm'} || die "DBI.pm not in %INC!";
	$dbidir =~ s:/DBI\.pm$::;
	return $dbidir;
}

sub dbd_dbi_arch_dir {
	my $dbidir = dbd_dbi_dir();
	my @try = (
	  map { "$_/auto/DBI" } @INC
	);
	my @xst = grep { -f "$_/Driver.xst" } @try;
	Carp::croak("Unable to locate Driver.xst in @try") unless @xst;
	Carp::carp( "Multiple copies of Driver.xst found in: @xst") if @xst > 1;
	print "Using DBI $DBI::VERSION installed in $xst[0]\n";
	return $xst[0];
}


sub dbd_postamble {
    my $dbidir = dbd_dbi_dir();
    my $xstdir = dbd_dbi_arch_dir();
    my $xstfile= '$(DBI_INSTARCH_DIR)/Driver.xst';
    if ($^O eq 'VMS') {
	$dbidir = vmsify($dbidir.'/');
	$xstdir = vmsify($xstdir.'/');
	$xstfile= '$(DBI_INSTARCH_DIR)Driver.xst';
    }

    # we must be careful of quotes, expecially for Win32 here.
    '
# This section was generated by DBI::DBD::dbd_postamble()
DBI_INST_DIR='.$dbidir.'
DBI_INSTARCH_DIR='.$xstdir.'
DBI_DRIVER_XST='.$xstfile.'

# The main dependancy (technicaly correct but probably not used)
$(BASEEXT).c: $(BASEEXT).xsi

# This dependancy is needed since MakeMaker uses the .xs.o rule
$(BASEEXT)$(OBJ_EXT): $(BASEEXT).xsi

# This line should not be needed (because it is not right)
#$(BASEEXT).xs: $(BASEEXT).xsi

$(BASEEXT).xsi: $(DBI_DRIVER_XST)
	$(PERL) -p -e "s/~DRIVER~/$(BASEEXT)/g" < $(DBI_DRIVER_XST) > $(BASEEXT).xsi
';
}

1;

__END__
