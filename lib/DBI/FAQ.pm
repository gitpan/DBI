#
# $Id: FAQ.pm,v 1.1 1997/06/11 23:03:50 timbo Exp $
#
# Copyright (c)1996-97 Alligator Descartes <descarte@hermetica.com>

package DBI::FAQ;

=head1 NAME

DBI::FAQ - Frequently Asked Questions for the Perl5 Database Interface

=head1 SYNOPSIS

    shell% perldoc DBI::FAQ

=head1 DESCRIPTION

                   DBI Frequently Asked Questions v.0.32
                        Last updated: May 28th, 1997
                                      
    1. Basic Information & Information Sources
         1. What is DBI, DBperl, Oraperl and *perl?
         2. Where can I get it from?
         3. Where can I get more information?
         4. Where can I get documentation on it?
         5. Are there any DBI Mailing Lists I can join?
         6. Are there any DBI Mailing List Archives?

    2. Compilation problems or "It fails the tests!"
          + DBI
          + Oracle
          + mSQL
          + Informix

    3. Platform and Driver Issues
         1. What's the difference between ODBC and DBI?
         2. Is DBI supported under Windows 95/NT platforms?
         3. Can I access Microsoft Access or SQL-Server databases with
            DBI?
         4. Is there a DBI for <insert favourite database here>?
         5. What's DBM? and why should I use DBI instead?
         6. When will mSQL-2 be supported?
         7. What database do you recommend me using?
         8. Is <insert feature here> supported in DBI?

    4. CGI and WWW Issues
         1. Is DBI any use for CGI programming?
         2. How do I get faster connection times with DBD::Oracle and CGI
         3. How do I get persistent database connections with DBI and
            CGI?
         4. ``When I run a perl script from the command line, it works,
            when I run it under the httpd, it fails!'' Why?

    5. General Programming and Technical Issues
         1. Can I do multi-threading with DBI?
         2. How do I handle BLOB data with DBI?
         3. How can I invoke stored procedures with DBI?
         4. How can I get return values from stored procedures with DBI?
         5. How can I create or drop a database with DBI?
         6. How can I commit or rollback a statement with DBI?
         7. How are NULL values handled by DBI?
         8. What are these func() methods all about?
       
     _________________________________________________________________
                                      
  1.1 What is DBI, DBperl, Oraperl and *perl?
  
To quote Tim Bunce, the architect and author of DBI:
   
     "DBI is a database access Application Programming Interface (API)
     for the Perl Language. The DBI API Specification defines a set of
     functions, variables and conventions that provide a consistent
     database interface independant of the actual database being used."
     
In simple language, the DBI interface allows users to access multiple
database types transparently. So, if you connecting to an Oracle,
Informix, mSQL, Sybase or whatever database, you don't need to know
the underlying mechanics of the 3GL layer. The API defined by DBI will
work on all these database types.

A similar benefit is gained by the ability to connect to two different
databases of different vendor within the one perl script, ie, I want
to read data from an Oracle database and insert it back into an
Informix database all within one program. The DBI layer allows you to
do this simply and powerfully.

DBperl is the old name for the interface specification. It's usually
now used to denote perl4 modules on database interfacing, such as,
oraperl, isqlperl, ingperl and so on. These interfaces didn't have a
standard API and are generally not supported.

Here's a list of DBperl modules, their corresponding DBI counterparts
and support information. Please note, the author's listed here
generally do not maintain the DBI module for the same database. These
email addresses are unverified and should only be used for queries
concerning the perl4 modules listed below. DBI driver queries should
be directed to the mailing list.
   
 Module Name     Database Required       Author                  DBI
 -----------     -----------------       ------                  ---
 Sybperl         Sybase                  Michael Peppler         DBD::Sybase
                                         <mpeppler@itf.ch>
 Oraperl         Oracle 6 & 7            Kevin Stock             DBD::Oracle
                                         <dbi-users@fugue.com>
 Ingperl         Ingres                  Tim Bunce & Ted Lemon   DBD::Ingres
                                         <dbi-users@fugue.com>
 Interperl       Interbase               Buzz Moschetti          DBD::Interbase
                                         <buzz@bear.com>
 Uniperl         Unify 5.0               Rick Wargo              None
                                         <rickers@coe.drexel.edu>
 Pgperl          Postgres                Igor Metz               None
                                         <metz@iam.unibe.ch>
 Btreeperl       NDBM                    John Conover            SDBM?
                                         <john@johncon.com>
 Ctreeperl       C-Tree                  John Conover            None
                                         <john@johncon.com>
 Cisamperl       Informix C-ISAM         Mathias Koerber         DBD::C-ISAM
                                         <mathias@unicorn.swi.com.sg>
 Duaperl         X.500 Directory User    Eric Douglas            None
                   Agent

However, some DBI modules have DBperl emulation layers, so,
DBD::Oracle comes with an Oraperl emulation layer, which allows you to
run legacy oraperl scripts wihtout modification. The emulation layer
translates the oraperl API calls into DBI calls and executes them
through the DBI switch.

Here's a table of emulation layer information:

 Module          Emulation Layer         Status
 ------          ---------------         ------
 DBD::Oracle     Oraperl                 Complete
 DBD::Informix   Isqlperl                Under development
 DBD::Sybase     Sybperl                 Working? ( Needs verification )
 DBD::mSQL       Msqlperl                Experimentally released with DBD::mSQL-0.61

The Msqlperl emulation is a special case. Msqlperl is a perl5 driver
for mSQL databases, but does not conform to the DBI Specification.
It's use is being deprecated in favour of DBD::mSQL.
   
     _________________________________________________________________
                                      
  1.2. Where can I get it from?
  
DBI is primarily distributed from:
   
     ftp://ftp.demon.co.uk/pub/perl/db
     
The Comprehensive Perl Archive Network resources should be used for
retrieving up-to-date versions of the drivers, since local mirror
sites usually lag. For more specific version information and exact
URLs of drivers, please see the drivers list and the DBI Switch pages.
   
     _________________________________________________________________
                                      
  1.3. Where can I get more information?
  
There are a few information sources on DBI.

     * The DBI documentation

Typing

  perldoc DBI

should present you with the official (but slightly incomplete) DBI manual.

     * DBI Specification
       http://www.hermetica.com/technologia/DBI/doc/dbispec

The DBI Specification lays out and old version of the DBI
interface. It should be noted that some modules, notably DBD::mSQL
and DBD::Informix, vary from this occasionally. This document
should be regarded as being of historical interest only and should
not serve as a programming manual, or authoratative in any sense.
However, it is still a very useful reference source.

     * Oraperl documentation

For users of the Oraperl emulation layer bundled with DBD::Oracle, typing:
       
         perldoc Oraperl

will produce an updated copy of the original oraperl man page
written by Kevin Stock for perl4. The oraperl API is fully listed
and described there.

     * Rambles, Tidbits and Observations
       http://www.hermetica.com/technologia/DBI/index.html#tidbits

There are a series of occasional rambles from various people on the DBI
mailing lists who, in an attempt to clear up a simple point, end up
drafting fairly comprehensive documents. These are quite often varying
in quality, but do provide some insights into the workings of the
interfaces.

     * ``DBI -- The perl5 Database Interface''
     
This is an article written by Alligator Descartes and Tim Bunce on the
structure of DBI. It was published in issue 5 of ``The Perl Journal''.
It's extremely good. Go buy the magazine. In fact, buy all of them!

     * A Book........

A book, to be written by Alligator Descartes and Tim Bunce is currently
in a proposal stage to a publisher. We'll keep you posted...

     * README files

The README files included with each driver occasionally contains some
useful information ( no, really! ) that may be pertinent to the user.
Please read them. It makes our worthless existences more bearable.

     * Mailing Lists

Visit http://www.fugue.com/dbi to subscribe. Only if you cannot
successfully use the form on the above WWW page then send mail
asking to subscribe to dbi-request@fugue.com (a human) and be
prepared to wait for it to happen. Using the WWW page is best.

There are three mailing lists for DBI run by Ted Lemon. These are:

	  + dbi-announce

This mailing list is for announcements only. Very low traffic. The
announcements are usually posted on the main DBI WWW page.

	  + dbi-dev

This mailing list is intended for the use of developers discussing
ideas and concepts for the DBI interface, API and driver mechanics.
Only any use for developers, or interested parties. Low traffic.

	  + dbi-users

This mailing list is a general discussion list used for bug reporting,
problem discussion and general enquiries. Medium traffic.

     Mailing List Archives
     
          + US Mailing List Archives
            http://www.coe.missouri.edu/~faq/lists/dbi.html
            Searchable hypermail archives of the three mailing lists, and
            some of the much older traffic have been set up for users to
            browse.
     
          + European Mailing List Archives
            http://www.rosat.mpe-garching.mpg.de/mailing-lists/PerlDB-Interest
            As per the US archive above.
       
     _________________________________________________________________
                                      
  2.1. Compilation problems or "It fails the test!"
  
First off, consult the online information about the module, beit DBI
itself, or a DBD, and see if it's a known compilation problem on your
architecture. These documents can be found at:

     http://www.hermetica.com/technologia/perl/DBI

If it's a known problem, you'll probably have to wait till it gets
fixed. If you're really needing it fixed, try the following:

     * Attempt to fix it yourself

This technique is generally not recommended to the faint-hearted.
If you do think you have managed to fix it, then, send a patch
file ( context diff ) to the author with an explanation of:

          + What the problem was, and test cases, if possible.
          + What you needed to do to fix it. Please make sure you mention
            everything.
          + Platform information, database version, perl version, module
            version and DBI version.

     * Email the author (but please don't whinge!)

Please email the address listed in the WWW pages for whichever driver
you are having problems with. Do not directly email the author at a
known address unless it corresponds with the one listed.

We tend to have real jobs to do, and we do read the mailing lists for
problems. Besides, we may not have access to <insert your favourite
brain-damaged platform here> and couldn't be of any assistance anyway!
Apologies for sounding harsh, but that's the way of it!

However, you might catch one of these creative genii at 3am when we're
doing this sort of stuff anyway, and get a patch within 5 minutes. The
atmosphere in the DBI circle is that we do appreciate the users'
problems, since we work in similar environments.

If you are planning to email the author, please furnish as much
information as possible, ie: ALL the information off the README file in
the problematic module. And we mean ALL of it. We don't put lines like
that in documentation for the good of our health, or to meet obscure
README file standards of length. If you have a core dump, try the
Devel::CoreStack module for generating a stack trace from the core
dump. Send us that too.  Devel::CoreStack can be found at CPAN + Module
versions, perl version, test cases, operating system versions and any
other pertinent information.

Remember, the more information you send us, the quicker we can track
problems down. If you send us nothing, expect nothing back.

     * Email the dbi-users Mailing List

It's usually a fairly intelligent idea to cc the mailing list anyway
with problems. The authors all read the lists, so you lose nothing by
mailing there.

     _________________________________________________________________

  3.1 What's the difference between ODBC and DBI?

Good question! To be filled in more detail!

     _________________________________________________________________

  3.2 Is DBI supported under Windows 95 / NT platforms?

Finally, yes! Jeff Urlwin has been working diligently on building
DBI and DBD::Oracle under these platforms, and, with the advent of a
stabler perl and a port of MakeMaker in Perl 5.004, the project has
come on by great leaps and bounds.

These patches and executables are now released. See the WWW page.

     _________________________________________________________________

  3.3 Can I access Microsoft Access or SQL-Server databases with DBI?

Supplied with DBI-0.79 ( and later ) is an experimental DBI 'emulation
layer' for the Win32::ODBC module. It's called DBI::W32ODBC and is, at
the moment, very minimal. You will need the Win32::ODBC module. Given
its status, problem reports without fixes are likely to be ignored.
You will also need the Win32 DBI patch kit as supplied by Jeff Urlwin.

Therefore, theoretically, yes, you can access Microsoft Access and
SQL-Server databases from DBI via ODBC.

     _________________________________________________________________

  3.4 Is the a DBD for <insert favourite database here>?

Is is listed on the drivers page? If not, no. A complete absence of a
given database driver from that page means that no-one has announced
any intention to work on it.

A corollary of the above statement implies that if you see an
announcement for a driver not on the above page, there's a good chance
it's not actually a DBI driver, and may not conform to the
specifications.

     _________________________________________________________________

  3.5 What's DBM? And why should I use DBI instead?

Extracted from ``DBI - The Database Interface for Perl 5'':

     UNIX was originally blessed with simple file-based `databases',
     namely the dbm system. dbm lets you store data in files, and
     retrieve that data quickly. However, it also has serious
     drawbacks.

    1. File Locking
       The dbm systems did not allow particularly robust file locking
       capabilities, nor any capability for correcting problems arising
       through simultaneous writes [ to the database ].

    2. Arbitrary Data Structures
       The dbm systems only allows a single fixed data structure:
       key-value pairs. That value could be a complex object, such as a
       [ C ] struct, but the key had to be unique. This was a large
       limitation on the usefulness of dbm systems.

     However, dbm systems still provide a useful function for users
     with simple datasets and limited resources, since they are fast,
     robust and extremely well-tested. Perl modules to access dbm
     systems have now been integrated into the core Perl distribution
     via the AnyDBM_File module.''

To sum up, DBM is a perfectly satisfactory solution for essentially
read-only databases, or small and simple datasets. However, for more
powerful and scaleable datasets, not to mention robust transactional
locking, users are recommended to use DBI.

     _________________________________________________________________

  3.6 When will mSQL-2 be supported?

As of DBD::mSQL-0.61, there has been support for mSQL-2. However, there
is no real support for any of the new methods added to the core mSQL
library regarding index support yet. These are forthcoming and will be
accessible via func() methods private to DBD::mSQL

     _________________________________________________________________

  3.7 What database do you recommend me using?

This is a particularly thorny area in which an objective answer is
difficult to come by, since each dataset, proposed usage and system
configuration differs from person to person.

From the current author's point of view, if the dataset is
relatively small, being tables of less than 1 million rows, and less
than 1000 tables in a given database, then mSQL is a perfectly
acceptable solution to your problem. This database is extremely cheap,
is wonderfully robust and has excellent support. More information is
available here.

If the dataset is larger than 1 million row tables or 1000 tables, or
if you have either more money, or larger machines, I would recommend
Oracle7 RDBMS. See here for more information.

In the case of WWW fronted applications, mSQL may be a better option
due to slow connection times between a CGI script and the Oracle
RDBMS and also the amount of resource each Oracle connection will
consume.  mSQL is lighter resource-wise and faster.

These views are not necessarily representative of anyone else's
opinions, and do not reflect any corporate sponsorship or views.
They are provided as-is.
     _________________________________________________________________

  3.8 Is <insert feature here> supported in DBI?

Given that we're making the assumption that the feature you have
requested is a non-standard database-specific feature, then the
answer will be no.

DBI reflects a generic API that will work for most databases, and
has no database-specific functionality.

However, driver authors may, if they so desire, include hooks to
database-specific functionality through the func() method defined in
the DBI API. Script developers should note that use of functionality
provided via the func() methods is unlikely to be portable across
databases.

     _________________________________________________________________

  4.1 Is DBI any use for CGI programming?

In a word, yes! DBI is hugely useful for CGI programming! In fact, I
would tentatively say that CGI programming is one of two top uses
for DBI.

DBI confers the ability to CGI programmers to power WWW-fronted
databases to their users, which provides users with vast quantities
of ordered data to play with. DBI also provides the possibility
that, if a site is receiving far too much traffic than their
database server can cope with, they can upgrade the database server
behind the scenes with no alterations to the CGI scripts.

     _________________________________________________________________

  4.2 How do I get faster connection times with DBD::Oracle and CGI?

Contributed by John D. Groenveld

The Apache httpd maintains a pool of httpd children to service client
requests.

Using the Apache mod_perl module by Doug MacEachern, the perl
interpreter is embedded with the httpd children. The CGI, DBI, and your
other favorite modules can be loaded at the startup of each child.
These modules will not be reloaded unless changed on disk.

     _________________________________________________________________

  4.3 How do I get persistent connections with DBI and CGI?

Contributed by John D. Groenveld

Using Edmund Mergl's Apache::DBI, database logins are stored in a
hash with each of these httpd child. If your application is based on
a single database user, this connection can be started with each
child.  Currently, database connections cannot be shared between
httpd children.

     _________________________________________________________________

  4.4 ``When I run a perl script from the command line, it works, but,
  when I run it under the httpd, it fails!'' Why?

Basically, a good chance this is occurring is due to the fact that
the user that you ran it from the command line as has a correctly
configured set of environment variables, in the case of DBD::Oracle,
variables like $ORACLE_HOME, $ORACLE_SID or TWO_TASK.

The httpd process usually runs under the user id of nobody, which
implies there is no configured environment. Any scripts attempting
to execute in this situation will correctly fail.

To solve this problem, set the environment for your database in a
BEGIN { } block at the top of your script. This will solve the
problem.

Similarly, you should check your httpd error logfile for any clues,
as well as the ``Idiot's Guide To Solving Perl / CGI Problems'' and
``Perl CGI Programming FAQ'' for further information. It is unlikely
the problem is DBI-related.

     _________________________________________________________________

  5.1 Can I do multi-threading with DBI?

As of the current date of this FAQ ( see top of page ), no. perl does
not support multi-threading. However, multi-threading is expected to
become part of the perl core distribution as of version 5.005, which
implies that DBI may support multi-threading fairly soon afterwards.

For some OCI example code for Oracle that has multi-threaded SELECT
statements, see:

 OCI Multi-threading examples

     _________________________________________________________________

  5.2 How do I handle BLOB data with DBI?

To be written.

     _________________________________________________________________

  5.3 How can I invoke stored procedures with DBI?

To be written.

     _________________________________________________________________

  5.4 How can I get return values from stored procedures with DBI?

To be written.

     _________________________________________________________________

  5.5 How can I create or drop a database with DBI?

Database creation and deletion are concepts that are entirely too
abstract to be adequately supported by DBI. For example, Oracle does
not support the concept of dropping a database at all! Also, in
Oracle, the database server essentially is the database, whereas in
mSQL, the server process runs happily without any databases created
in it. The problem is too disparate to attack.

Some drivers, therefore, support database creation and deletion
through the private func() methods. You should check the
documentation for the drivers you are using to see if they support
this mechanism.

     _________________________________________________________________

  5.6 How can I commit or rollback a statement with DBI?

To be written.

     _________________________________________________________________

  5.7 How are NULL values handled by DBI?

NULL values in DBI are specified to be treated as the value undef.
NULLs can be inserted into databases as NULL, for example:

    $rv = $dbh->do( "INSERT INTO table VALUES( NULL )" );

but when queried back, the NULLs should be tested against undef. This
is standard across all drivers.
   
     _________________________________________________________________
                                      
  5.8 What are these func() methods all about?
  
The func() method is defined within DBI as being an entry point for
database-specific functionality, eg, the ability to create or drop
databases. Invoking these driver-specific methods is simple, for
example, to invoke a createDatabase method that has one argument, we
would write:

    $rv = $dbh->func( 'argument', 'createDatabase' );

Software developers should note that the func() methods are
non-portable between databases.

=head1 AUTHORS

Main FAQ written by Alligator Descartes with contributions by Jeff Urlwin, 
Tim Bunce and John D. Groenveld.

=head1 COPYRIGHT

This FAQ is Copyright(c)1996-1997 Alligator Descartes. Contributed sections
are under copyright of the original authors.
Permission to distribute this document, in full or part, via email,
usenet or ftp/http archives or printed copy is granted providing that
no charges are involved, reasonable attempt is made to use the most
current version, and all credits and copyright notices are retained.
Requests for other distribution rights, including incorporation in
commercial products, such as books, magazine articles, or CD-ROMs
should be made to C<descarte@hermetica.com>.

=cut
