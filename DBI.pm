require 5.003;

{
package DBI;

$VERSION = '0.73';

my $Revision = substr(q$Revision: 1.59 $, 10);

# $Id: DBI.pm,v 1.59 1996/10/10 15:55:12 timbo Exp $
#
# Copyright (c) 1995, Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use Carp;
use DynaLoader ();
use Exporter ();

@ISA = qw(Exporter DynaLoader);

# Make some utility functions available if asked for
@EXPORT_OK = qw(neat neat_list dump_results);
@EXPORT    = qw();	# Export _nothing_ by default

use strict;

$DBI::dbi_debug = $ENV{PERL_DBI_DEBUG} || 0;
carp "Loaded DBI.pm" if $DBI::dbi_debug;

bootstrap DBI;

DBI->_debug_dispatch($DBI::dbi_debug) if $DBI::dbi_debug;

%DBI::installed_drh = ();  # maps driver names to installed driver handles


# Setup special DBI dynamic variables. See DBI::var::FETCH for details.
# These are dynamically associated with the last handle used.
tie $DBI::err,    'DBI::var', '*err';    # special case: referenced via IHA list
tie $DBI::state,  'DBI::var', '"state';  # special case: referenced via IHA list
tie $DBI::lasth,  'DBI::var', '!lasth';  # special case: return boolean
tie $DBI::errstr, 'DBI::var', '&errstr'; # call &errstr in last used pkg
tie $DBI::rows,   'DBI::var', '&rows';   # call &rows   in last used pkg
sub DBI::var::TIESCALAR{ my($var) = $_[1]; bless \$var, 'DBI::var'; }
sub DBI::var::STORE{ Carp::carp "Can't modify \$DBI::${$_[0]} special variable" }


# --- Dynamically create the DBI Standard Interface

my $std = undef;
my $keeperr = { O=>0x04 };

my @TieHash_IF = (	# Generic Tied Hash Interface
	'STORE'   => $std,
	'FETCH'   => $std,
	'FIRSTKEY'=> $keeperr,
	'NEXTKEY' => $keeperr,
	'EXISTS'  => $keeperr,
	'CLEAR'   => $keeperr,
	'DESTROY' => $keeperr,
);
my @Common_IF = (	# Interface functions common to all DBI classes
	func    =>	{					O=>0x02	},
	event   =>	{ U =>[2,3,'$message, $retvalue'],	O=>0x04 },
	debug   =>	{ U =>[1,2,'[$debug_level]'],		O=>0x04 },
	private_data =>	{ U =>[1,1],				O=>0x04 },
	errstr  =>	$keeperr,
	rows    =>	$keeperr,
);

my %DBI_IF = (	# Define the DBI Interface:

    dr => {		# Database Driver Interface
	'connect'  =>	{ U =>[1,5,'[$db [,$user [,$passwd [,\%attr]]]]'] },
	'disconnect_all'=>{ U =>[1,1] },
	data_sources => { U =>[1,1] },
	@Common_IF,
	@TieHash_IF,
    },
    db => {		# Database Session Class Interface
	commit     =>	{ U =>[1,1] },
	rollback   =>	{ U =>[1,1] },
	'do'       =>	{ U =>[2,0,'$statement [, \%attribs [, @bind_params ] ]'] },
	prepare    =>	{ U =>[2,3,'$statement [, \%attribs]'] },
	handler    =>	{ U =>[2,2,'\&handler'] },
	errstate   =>	{ U =>[1,1], O=>0x04 },
	errmsg     =>	{ U =>[1,1], O=>0x04 },
	disconnect =>	{ U =>[1,1] },
	tables     =>	{ U =>[1,1] },
	quote      =>	{ U =>[2,2, '$str'] },
	@Common_IF,
	@TieHash_IF,
    },
    st => {		# Statement Class Interface
	bind_col   =>	{ U =>[3,4,'$column, \\$var [, \%attribs]'] },
	bind_columns =>	{ U =>[3,0,'\%attribs, \\$var1 [, \\$var2, ...]'] },
	bind_param =>	{ U =>[3,4,'$parameter, $var [, \%attribs]'] },
	bind_param_inout => { U =>[4,5,'$parameter, \\$var, $maxlen, [, \%attribs]'] },
	execute    =>	{ U =>[1,0,'[@args]'] },
	fetch      =>	undef, # no checks, no args, max speed
	fetchrow   =>	undef, # no checks, no args, max speed
	readblob   =>	{ U =>[4,5,'$field, $offset, $len [, \\$buf [, $bufoffset]]'] },
	blob_read  =>	{ U =>[4,5,'$field, $offset, $len [, \\$buf [, $bufoffset]]'] },
	blob_copy_to_file => { U =>[3,3,'$field, $filename_or_handleref'] },
	finish     => 	{ U =>[1,1] },
	@Common_IF,
	@TieHash_IF,
    },
);

my($class, $method);
foreach $class (keys %DBI_IF){
    my %pkgif = %{$DBI_IF{$class}};
    foreach $method (keys %pkgif){
	DBI->_install_method("DBI::${class}::$method", 'DBI.pm',
			$pkgif{$method});
    }
}

# End of init code


END {
    warn "DBI::END\n" if $DBI::dbi_debug;
    # Let drivers know why we are calling disconnect_all:
    $DBI::PERL_ENDING = 1;	# Perl is END'ing
    DBI->disconnect_all();
    warn "DBI::END complete\n" if $DBI::dbi_debug;
}



# --- The DBI->connect Front Door function

sub connect {
    my $class = shift;
    my($database, $user, $passwd, $driver, $attr) = @_;

    $database ||= $ENV{DBI_DBNAME} || '';
    $driver   ||= $ENV{DBI_DRIVER} || '';
    $attr ||= '';

    warn "DBI->connect($database, $user, $passwd, $driver, $attr)\n"
	    if $DBI::dbi_debug;
    die 'Usage: DBI->connect([$db [,$user [,$passwd [, $driver [,\%attr]]]]])'
	    unless ($class eq 'DBI' && @_ <= 6);

    # Experimental hook
    return DBIODBC->connect(@_) if $database =~ m/^[A-Z]+=/; # DSN= etc

    confess "DBI->connect() currently needs a driver" unless $driver;

    # Note that the same $attr hash ref is passed to both
    # install_driver and connect. Sad but true.

    my $drh = $DBI::installed_drh{$driver};
    unless (defined $drh){
	$drh = DBI->install_driver($driver, $attr)
		or confess "DBI->install_driver($driver) failed";
    }
    warn "DBI->connect using $driver driver $drh\n" if $DBI::dbi_debug;

    my $dbh = $drh->connect($database, $user, $passwd, $attr);
    warn "DBI->connect = $dbh\n" if $DBI::dbi_debug;

    $dbh;
}


sub disconnect_all {
    warn "DBI::disconnect_all @_\n" if $DBI::dbi_debug;
    foreach(keys %DBI::installed_drh){
	warn "DBI::disconnect_all for '$_'\n" if $DBI::dbi_debug;
	my $drh = $DBI::installed_drh{$_};
	next unless ref $drh;	# avoid problems on premature death
	$drh->disconnect_all();
    }
}


sub install_driver {
    my($class, $driver_name, $install_attributes) = @_;

    Carp::carp "DBI->install_driver @_" if $DBI::dbi_debug;
    die 'usage DBI->install_driver($driver_name [, \%attribs])'
	unless ($class eq 'DBI' and $driver_name and @_<=3);

    # --- load the code
    eval "package DBI::_firesafe; require DBD::$driver_name";
    confess "install_driver($driver_name) failed: $@" if $@;
    warn "DBI->install_driver($driver_name) loaded\n" if $DBI::dbi_debug;

    # --- do some behind-the-scenes checks and setups on the driver
    _setup_driver($driver_name);

    # --- run the driver function
    $install_attributes = {} unless $install_attributes;
    my $drh = eval "DBD::${driver_name}->driver(\$install_attributes)";
    croak "DBD::$driver_name initialisation failed: $@"
	unless $drh && ref $drh && !$@;

    warn "DBI->install_driver($driver_name) = $drh\n" if $DBI::dbi_debug;
    $DBI::installed_drh{$driver_name} = $drh;
    $drh;
}

sub _setup_driver {
    my($driver_name) = @_;

    # --- do some behind-the-scenes checks and setups on the driver
    foreach(qw(dr db st)){
	no strict 'refs';
	my $class = "DBD::${driver_name}::$_";
	push(@{"${class}::ISA"},     "DBD::_::$_");
	push(@{"${class}_mem::ISA"}, "DBD::_mem::$_");
	warn "install_driver($driver_name): setup \@ISA for $class\n"
	    if ($DBI::dbi_debug>=3);
    }
}


sub internal {
    &DBD::Switch::dr::driver;	# redirect with args
}


sub available_drivers {
    my(@drivers, $d, $f);
    local(*DBI::DIR);
    my(%seen_dir, %seen_dbd);
    foreach $d (@INC){
	chomp($d); # perl 5 beta 3 bug in #!./perl -Ilib from Test::Harness
	next unless -d "$d/DBD";
	next if $seen_dir{$d};
	$seen_dir{$d} = 1;
	opendir(DBI::DIR,"$d/DBD") || Carp::carp "opendir $d/DBD: $!\n";
	foreach $f (sort readdir(DBI::DIR)){
	    next unless $f =~ s/\.pm$//;
	    if ($seen_dbd{$f}){
		Carp::carp "DBD::$f in $d is hidden by DBD::$f in $seen_dbd{$f}\n";
            } else {
		push(@drivers, $f);
	    }
	    $seen_dbd{$f} = $d;
	}
	closedir(DBI::DIR);
    }
    @drivers;
}


sub neat_list {
    my($listref, $maxlen, $sep) = @_;
    $maxlen = 0 unless defined $maxlen;
    $sep = ", " unless defined $sep;
    join(", ", map { neat($_,$maxlen) } @$listref);
}


sub dump_results {
    my($sth, $maxlen, $sep) = @_;
    $maxlen ||= 35;
    $sep    ||= "\n";
    my $rows = 0;
    my $ref;
#$sth->debug(2);
    while($ref = $sth->fetch) {
	print $sep if $rows++;
	print neat_list($ref,$maxlen);
    }
#$sth->debug(0);
    print "\n$rows rows".($DBI::err ? " ($DBI::err: $DBI::errstr)" : "")."\n";
    $rows;
}


sub MakeMakerAttribs {
    # return extra attributes for DBD Makefile.PL WriteMakefile()
    ();
}


# --- Private Internal Function for Creating New DBI Handles

sub _new_handle {
    my($class, $parent, $attr, $imp_data) = @_;
    $parent = '' unless $parent;

    confess 'Usage: DBI::_new_handle'
	.'($class_name, parent_handle, \%attribs, $imp_data)'."\n"
	.'got: ('.join(", ",$class, $parent, $attr, $imp_data).")\n"
	unless (@_ == 4
		and (!$parent or ref $parent)
		and ref $attr eq 'HASH'
		);

    my $imp_class = $attr->{ImplementorClass} or
	croak "_new_handle($class): 'ImplementorClass' attribute not given";

    printf(STDERR "    New $class (for $imp_class, parent=$parent, id=%s)\n",
	    ($imp_data||''))
	if ($DBI::dbi_debug >= 2);

    Carp::carp "_new_handle($class): "
		."invalid implementor class '$imp_class' given\n"
	    unless $imp_class =~ m/::(dr|db|st)$/;

    # This is how we create a DBI style Object:
    my(%hash, $i, $h);
    $i = tie    %hash, $class, $attr;  # ref to inner hash (for driver)
    $h = bless \%hash, $class;         # ref to outer hash (for application)
    # The above tie and bless may migrate down into _setup_handle()...
    # Now add magic so DBI method dispatch works
    my @imp_data;
    push(@imp_data, $imp_data) if defined $imp_data;
    DBI::_setup_handle($h, $imp_class, $parent, @imp_data);

    warn "    New $class => $h (inner=$i) for $imp_class\n"
	if ($DBI::dbi_debug >= 2);
    return $h unless wantarray;
    ($h, $i);
}
{   # implement minimum constructors for the tie's (could be moved to xs)
    package DBI::dr; sub TIEHASH { bless $_[1] };
    package DBI::db; sub TIEHASH { bless $_[1] };
    package DBI::st; sub TIEHASH { bless $_[1] };
}


# These three constructors are called by the drivers

sub _new_drh {	# called by DBD::<drivername>::driver()
    my($class, $initial_attr, $imp_data) = @_;
    # Provide default storage for State,Err and Errstr.
    # State must be undef to get automatic faking in DBI::var::FETCH
    my($h_state_store, $h_err_store, $h_errstr_store) = (undef, 0, '');
    my $attr = {
	'ImplementorClass' => $class,
	# these attributes get copied down to child handles
	'Handlers'	=> [],
	'State'		=> \$h_state_store,  # Holder for DBI::state
	'Err'		=> \$h_err_store,    # Holder for DBI::err
	'Errstr'	=> \$h_errstr_store, # Holder for DBI::errstr
	'Debug' 	=> 0,
	%$initial_attr,
	'Type'=>'dr',
    };
    _new_handle('DBI::dr', undef, $attr, $imp_data);
}

sub _new_dbh {	# called by DBD::<drivername>::dr::connect()
    my($drh, $initial_attr, $imp_data) = @_;
    my($imp_class) = $drh->{ImplementorClass};
    $imp_class =~ s/::dr$/::db/;
    confess "new db($drh, $imp_class): not given an driver handle"
	    unless $drh->{Type} eq 'dr';
    my $attr = {
	'ImplementorClass' => $imp_class,
	%$initial_attr,
	'Type'   => 'db',
	'Driver' => $drh,
    };
    _new_handle('DBI::db', $drh, $attr, $imp_data);
}

sub _new_sth {	# called by DBD::<drivername>::db::prepare()
    my($dbh, $initial_attr, $imp_data) = @_;
    my($imp_class) = $dbh->{ImplementorClass};
    $imp_class =~ s/::db$/::st/;
    confess "new st($dbh, $imp_class): not given a database handle"
	unless (ref $dbh eq 'DBI::db' and $dbh->{Type} eq 'db');
    my $attr = {
	'ImplementorClass' => $imp_class,
	%$initial_attr,
	'Type'     => 'st',
	'Database' => $dbh,
    };
    _new_handle('DBI::st', $dbh, $attr, $imp_data);
}

} # end of DBI package scope



# --------------------------------------------------------------------
# === The internal DBI Switch pseudo 'driver' class ===

{   package DBD::Switch::dr;
    DBI::_setup_driver('Switch');	# sets up @ISA
    require Carp;

    $imp_data_size = 0;
    $err = 0;

    sub driver {
	return $drh if $drh;	# a package global

	my $inner;
	($drh, $inner) = DBI::_new_drh('DBD::Switch::dr', {
		'Name'    => 'Switch',
		'Version' => $DBI::VERSION,
		# the Attribution is defined as a sub as an example
		'Attribution' => sub { "DBI-$DBI::VERSION Switch by Tim Bunce" },
	    }, \$err);
	Carp::confess("DBD::Switch init failed!") unless ($drh && $inner);
	$DBD::Switch::dr::drh;
    }

    sub FETCH {
	my($drh, $key) = @_;
	return DBI->_debug_dispatch if $key eq 'DebugDispatch';
	return undef if $key eq 'DebugLog';	# not worth fetching, sorry
	return $drh->DBD::_::dr::FETCH($key);
	undef;
    }
    sub STORE {
	my($drh, $key, $value) = @_;
	if ($key eq 'DebugDispatch') {
	    DBI->_debug_dispatch($value);
	} elsif ($key eq 'DebugLog') {
	    DBI->_debug_dispatch(-1, $value);
	} else {
	    $drh->DBD::_::dr::STORE($key, $value);
	}
    }
}


# --------------------------------------------------------------------
# === OPTIONAL MINIMAL BASE CLASSES FOR DBI SUBCLASSES ===

# We only define default methods for harmless functions.
# We don't, for example, define a DBD::_::st::prepare()

{   package DBD::_::common; # ====== Common base class methods ======
    use strict;

    # methods common to all handle types:

    *debug = \&DBI::_debug_handle;
    sub errstr	{ $DBI::err }	# errstr defaults to (tie'd) err value

    # generic TIEHASH default methods:
    sub FIRSTKEY { undef }
    sub NEXTKEY  { undef }
    sub EXISTS   { defined($_[0]->FETCH($_[1])) } # to be sure
    sub CLEAR    { Carp::carp "Can't CLEAR $_[0] (DBI)" }
}


{   package DBD::_::dr;  # ====== DRIVER ======
    @ISA = qw(DBD::_::common);
    use strict;
    use Carp;

    sub connect { # normally overridden, but a handy default
	my($drh, $dbname, $user, $auth)= @_;
	my($this) = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'User' => $user,
	    });
	$this;
    }
    sub disconnect_all {	# Driver must take responsibility for this
	Carp::confess "Driver has not implemented disconnect_all for @_";
    }
}


{   package DBD::_::db;  # ====== DATABASE ======
    @ISA = qw(DBD::_::common);
    use strict;

    sub quote	{
		my $self = shift;
		my $str = shift;
		$str=~s/'/''/g;		# ISO SQL2
		"'$str'";
	}

    sub rows	{ -1 }

    sub do {
	my($dbh, $statement, $attribs, @params) = @_;
	Carp::carp "\$h->do() attribs unused\n" if $attribs;
	my $sth = $dbh->prepare($statement) or return undef;
	$sth->execute(@params) or return undef;
	my $rows = $sth->rows;
	($rows == 0) ? "0E0" : $rows;
    }

    sub commit	{
	Carp::carp "commit: not supported by $_[0]\n" if $DBI::dbi_debug;
	undef;
    }
    sub rollback{
	Carp::carp "rollback: not supported by $_[0]\n" if $DBI::dbi_debug;
	undef;
    }
    sub disconnect  { undef }
}


{   package DBD::_::st;  # ====== STATEMENT ======
    @ISA = qw(DBD::_::common);
    use strict;

    sub finish  { undef }
    sub rows	{ -1 }
    # bind_param => not implemented - fail

    sub readblob {		# grandfather in for a version or two
	my $count if 0;		# trick to get static variable
	Carp::carp("Warning: readblob method renamed to blob_read()")
	    unless $count++;
	shift->blob_read(@_);
    }
    sub blob_copy_to_file {	# returns length or undef on error
	my($self, $field, $filename_or_handleref, $blocksize) = @_;
	my $fh = $filename_or_handleref;
	my($len, $buf) = (0, "");
	$blocksize ||= 512;	# not too ambitious
	local(*FH);
	unless(ref $fh) {
	    open(FH, ">$fh") || return undef;
	    $fh = \*FH;
	}
	while(defined($self->blob_read($field, $len, $blocksize, \$buf))) {
	    print $fh $buf;
	    $len += length $buf;
	}
	close(FH);
	$len;
    }

    # Drivers are required to implement *::st::DESTROY to encourage tidy-up
    sub DESTROY  { Carp::confess "Driver has not implemented DESTROY for @_" }
}

{   # See install_driver
    { package DBD::_mem::dr; @ISA = qw(DBD::_mem::common);	}
    { package DBD::_mem::db; @ISA = qw(DBD::_mem::common);	}
    { package DBD::_mem::st; @ISA = qw(DBD::_mem::common);	}
    # DBD::_mem::common::DESTROY is implemented in DBI.xs
}

1;
__END__

DBI for Perl 5  -  Function Summary  (Sep 29 1994)
---------------------------------------------------------------

NOTATION

Object Handles:

  DBI static 'top-level' class name
  $drh   Driver Handle (rarely seen or used)
  $dbh   Database Handle
  $sth   Statement Handle

note that Perl 5 will automatically destroy database and statement
objects if all references to them are deleted.

Object attributes are shown as:

  $handle->{'attribute_name'}  (type)

where (type) indicates the type of the value of the attribute,
if it's not a simple scalar:

  \@   reference to a list:  $h->{a}->[0]  or  @a = @{$h->{a}}
  \%   reference to a hash:  $h->{a}->{a}  or  %a = %{$h->{a}}


---------------------------------------------------------------
DBI OBJECTS

$dbh = DBI->connect([$database [, $username [, $auth [, $driver [, \%attribs]]]]]);
$rc  = DBI->disconnect_all;  # disconnect all database sessions

$drh = DBI->internal; # return $drh for internal Switch 'driver'
$drh = DBI->install_driver($driver_name [, \%attributes ] );
$rv  = DBI->install_method($class_method, $filename [, \%attribs]);

$DBI::err     same as DBI->internal->{LastDbh}->{Error}
$DBI::errstr  same as DBI->internal->{LastDbh}->{ErrorStr}
$DBI::state   ISO SQL/92 style SQLSTATE value
$DBI::rows    same as DBI->internal->{LastSth}->{ROW_COUNT}

DBI->connect calls DBI->install_driver if the driver has not been
installed yet. It then returns the result of $drh->connect.
It is important to note that DBI->install_driver always returns
a valid driver handle or it *dies* with an error message which
includes the string 'install_driver' and the underlying problem.
So, DBI->connect will die on an install_driver failure and will
only return undef on a connect failure, for which $DBI::errstr
will hold the error.

---------------------------------------------------------------
DRIVER OBJECTS (not normally used by an application)

$dbh = $drh->connect([$database [, $username [, $auth [, \%attribs]]]]]);

$drh->{Type}       "dr"
$drh->{Name}       (name of driver, e.g., Oracle)
$drh->{Version}
$drh->{Attribution}

Additional Attributes for internal DBI Switch 'driver'

$drh->{DebugDispatch}
$drh->{InstalledDrivers} (@)
$drh->{LastAdh}
$drh->{LastDbh}
$drh->{LastSth}


---------------------------------------------------------------
DATABASE OBJECTS

$rc  = $dbh->disconnect;			undef or 1
$rc  = $dbh->commit;				undef or 1
$rc  = $dbh->rollback;				undef or 1
$rc  = $dbh->do($statement [, \%attr]);

$sth = $dbh->prepare($statement [, \%attr]);
$sth = $dbh->tables();

$rv  = $dbh->errstate;
@ary = $dbh->errmsg;

$sql = $dbh->quote($str);

$dbh->{Type}       "db"
$dbh->{Name}       (name of database the handle is connected to)
$dbh->{Driver}     (\%)

$dbh->{Error}      normally use $db_error
$dbh->{ErrorStr}   normally use $db_errstr
$dbh->{ROW_COUNT}  normally use $db_rows


---------------------------------------------------------------
STATEMENT OBJECTS

$rc  = $sth->execute(@bind_values);    	undef, 0E0, 1, 2, ...
@ary = $sth->fetchrow;
$rc  = $sth->finish;                    undef or 1

$sth->{Type}       "st"
$sth->{Name}
$sth->{Database}   (\%)  # eg $sth->{Database}->{Driver}->{Name} !

$sth->{NAME}       (\@)
$sth->{NULLABLE}   (\@)
$sth->{TYPE}       (\@)
$sth->{PRECISION}  (\@)
$sth->{SCALE}      (\@)

$sth->{NUM_OF_FIELDS}  ($)
$sth->{NUM_OF_PARAMS}  ($)

---------------------------------------------------------------

Random WWW links

http://www-ccs.cs.umass.edu/db.html
http://www.odmg.org/odmg93/updates_dbarry.htm
http://www.jcc.com/sql_stnd.html
