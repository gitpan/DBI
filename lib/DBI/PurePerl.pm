########################################################################
package DBI;

########################################################################
#
# Copyright (c) 2002  Tim Bunce  Ireland.
#
# See COPYRIGHT section in DBI.pm for usage and distribution rights.
#
########################################################################
#
# Please send patches and bug reports to
#
# Jeff Zucker <jeff@vpservices.com>  with cc to <dbi-dev@perl.org>
#
########################################################################
#
# Comments starting with '#z' are Jeff's (as are all mistakes :-)
#
########################################################################

use strict;
use Carp;
require Symbol;

$DBI::PurePerl = $ENV{DBI_PUREPERL} || 1;
$DBI::PurePerl::VERSION = substr(q$Revision: 1.4 $, 10);

my $trace = $ENV{DBI_TRACE} || 0;
my $tfh = Symbol::gensym();
open $tfh, ">&STDERR" or warn "Can't dup STDERR: $!";

warn __FILE__ . " version " . $DBI::PurePerl::VERSION . "\n" if $trace;

my %last_method_except = map { $_=>1 } qw(FETCH STORE DESTROY _set_fbav set_err);

use constant SQL_ALL_TYPES => 0;
use constant SQL_ARRAY => 50;
use constant SQL_ARRAY_LOCATOR => 51;
use constant SQL_BINARY => (-2);
use constant SQL_BIT => (-7);
use constant SQL_BLOB => 30;
use constant SQL_BLOB_LOCATOR => 31;
use constant SQL_BOOLEAN => 16;
use constant SQL_CHAR => 1;
use constant SQL_CLOB => 40;
use constant SQL_CLOB_LOCATOR => 41;
use constant SQL_DATE => 9;
use constant SQL_DATETIME => 9;
use constant SQL_DECIMAL => 3;
use constant SQL_DOUBLE => 8;
use constant SQL_FLOAT => 6;
use constant SQL_GUID => (-11);
use constant SQL_INTEGER => 4;
use constant SQL_INTERVAL => 10;
use constant SQL_INTERVAL_DAY => 103;
use constant SQL_INTERVAL_DAY_TO_HOUR => 108;
use constant SQL_INTERVAL_DAY_TO_MINUTE => 109;
use constant SQL_INTERVAL_DAY_TO_SECOND => 110;
use constant SQL_INTERVAL_HOUR => 104;
use constant SQL_INTERVAL_HOUR_TO_MINUTE => 111;
use constant SQL_INTERVAL_HOUR_TO_SECOND => 112;
use constant SQL_INTERVAL_MINUTE => 105;
use constant SQL_INTERVAL_MINUTE_TO_SECOND => 113;
use constant SQL_INTERVAL_MONTH => 102;
use constant SQL_INTERVAL_SECOND => 106;
use constant SQL_INTERVAL_YEAR => 101;
use constant SQL_INTERVAL_YEAR_TO_MONTH => 107;
use constant SQL_LONGVARBINARY => (-4);
use constant SQL_LONGVARCHAR => (-1);
use constant SQL_MULTISET => 55;
use constant SQL_MULTISET_LOCATOR => 56;
use constant SQL_NUMERIC => 2;
use constant SQL_REAL => 7;
use constant SQL_REF => 20;
use constant SQL_ROW => 19;
use constant SQL_SMALLINT => 5;
use constant SQL_TIME => 10;
use constant SQL_TIMESTAMP => 11;
use constant SQL_TINYINT => (-6);
use constant SQL_TYPE_DATE => 91;
use constant SQL_TYPE_TIME => 92;
use constant SQL_TYPE_TIMESTAMP => 93;
use constant SQL_TYPE_TIMESTAMP_WITH_TIMEZONE => 95;
use constant SQL_TYPE_TIME_WITH_TIMEZONE => 94;
use constant SQL_UDT => 17;
use constant SQL_UDT_LOCATOR => 18;
use constant SQL_UNKNOWN_TYPE => 0;
use constant SQL_VARBINARY => (-3);
use constant SQL_VARCHAR => 12;
use constant SQL_WCHAR => (-8);
use constant SQL_WLONGVARCHAR => (-10);
use constant SQL_WVARCHAR => (-9);

use constant IMA_HAS_USAGE	=> 0x0001; #/* check parameter usage	*/
use constant IMA_FUNC_REDIRECT	=> 0x0002; #/* is $h->func(..., "method")*/
use constant IMA_KEEP_ERR	=> 0x0004; #/* don't reset err & errstr	*/
use constant IMA_spare		=> 0x0008; #/* */
use constant IMA_NO_TAINT_IN   	=> 0x0010; #/* don't check for tainted args*/
use constant IMA_NO_TAINT_OUT   => 0x0020; #/* don't taint results	*/
use constant IMA_COPY_STMT   	=> 0x0040; #/* copy sth Statement to dbh */
use constant IMA_END_WORK	=> 0x0080; #/* set on commit & rollback	*/
use constant IMA_STUB		=> 0x0100; #/* donothing eg $dbh->connected */

my %is_valid_attribute = map {$_ =>1 } qw(
    CompatMode  Warn  Active  InactiveDestroy  FetchHashKeyName  RootClass
    RowCacheSize  ChopBlanks  LongReadLen  LongTruncOk  RaiseError  PrintError
    HandleError  ShowErrorStatement  MultiThread  Taint  CachedKids  AutoCommit
    BegunWork  TraceLevel  NUM_OF_FIELDS  NUM_OF_PARAMS Attribution Version
    ImplementorClass Kids ActiveKids DebugDispatch Driver Statement Database
    Name Provider
);

sub valid_attribute {
    my $attr = shift;
    return 1 if $is_valid_attribute{$attr};
    return 1 if $attr =~ m/^[a-z]/; # starts with lowercase letter
    return 0
}

my $initial_setup;
sub initial_setup {
    $initial_setup = 1;
    untie $DBI::err;
    untie $DBI::errstr;
    untie $DBI::state;
    #tie $DBI::lasth,  'DBI::var', '!lasth';  # special case: return boolean
    #tie $DBI::rows,   'DBI::var', '&rows';   # call &rows   in last used pkg
}

sub  _install_method {
    my ( $caller, $method, $from, $param_hash ) = @_;
    initial_setup() unless $initial_setup;

    my ($class, $method_name) = $method =~ /^[^:]+::(.+)::(.+)$/;
    my $bitmask = $param_hash->{'O'} || 0;
    my @code_frag;

    push @code_frag, q{
	return $h->{$_[1]} if exists $h->{$_[1]};
    } if $method_name eq 'FETCH';
    push @code_frag, q{
	$h->{BegunWork} = 1;
	$h->{AutoCommit} = -900;
    } if $method_name eq 'begin_work';

    push @code_frag, "return;"		if IMA_STUB & $bitmask;
    push @code_frag, q{
	++$keep_err;
    } if IMA_KEEP_ERR & $bitmask;
    push @code_frag, q{
	$imp =~ s/^(.*)::[^:]+$/$1/;
	$method_name = $imp.'::db::'. pop @_;
    } if IMA_FUNC_REDIRECT & $bitmask;
    push @code_frag, q{
	$h->{Database}->STORE('Statement',$h->{Statement});
    } if IMA_COPY_STMT & $bitmask;
    push @code_frag, q{
	$h->{'BegunWork'}=0;
	$h->{'AutoCommit'}=-900;
    } if IMA_END_WORK & $bitmask;

    push @code_frag, q{
	$h->{err} = 0;
	$h->{errstr} = $DBI::state = '';
    } unless IMA_KEEP_ERR & $bitmask;	# see above

    my $method_code = q[ sub {
        my $h = $_[0];
        my $imp = $h->{"ImplementorClass"};
	my $keep_err;

        if ( $method_name eq 'STORE' and ($class eq 'db' or $class eq 'dr')) {
            my($h,$key,$value)=@_;
	    # bypass method call for private attributes
	    #return $h->{$key}=$value if $key =~ m/^[a-z]/; # XXX probably wrong

	    if ($key =~ /^[A-Z]/ and !valid_attribute($key)){
               croak sprintf "Can't set %s->{%s}: unrecognised attribute or invalid value %s",
		    $h,$key,$value;
            }
  	    if ( $key eq 'AutoCommit' ) {
              #z catch the DBD's failure on AutoCommit=0
              #  failure to do this was not caught by DBI/t*
	      if ($value == 0 and my $tmp=$imp->can('STORE')) {
                    eval { &$tmp($h,$key,$value); };
                    croak $@ if $@;
                    $h->{$key}=0 if $h->{$key}==-900;
                    return $value;
	      }
              return $h->{$key}=$value;
	    }
        }

	]
	. join("\n", @code_frag)
	. q[

        if ($trace) { local $^W; printf $tfh "    > $method_name(@_)\n"; }

        my $sub = $imp->can($method_name)
            or croak "Can't find $method_name method for $h";

	my @ret;

        #z HANDLE NESTED METHODS
        #  sort of what class_depth does in DBI.xs
        #
        $DBI::PurePerl::var->{'last_method'} = $method_name
             unless exists $last_method_except{$method_name};

        (wantarray) ? (@ret = &$sub(@_)) : (@ret = scalar &$sub(@_));

        if ($h->{'err'} and !$keep_err ) {

            my $mimp = $method_name;

            #z HANDLE NESTED METHOD FAILURES
            my $last = $DBI::PurePerl::var->{'last_method'};
            $mimp =~ s/STORE/$last/ if $last;

            my $estr = $h->{'errstr'}  || $DBI::errstr || $DBI::err || 'No Message :-(';
            my $msg = sprintf "%s %s failed: %s\n", $imp, $mimp, $estr;
            if ($h->{'ShowErrorStatement'} && $h->{'Statement'}) {
               $msg .= " for [\"".$h->{'Statement'}."\"]";
	    }
            my $do_croak=1;
            if (my $subsub = $h->{'HandleError'}) {
                my @hret;
                my $first_val = $ret[0];
                (wantarray)
		    ? (@hret = &$subsub($msg,$h,$first_val))
		    : (@hret = scalar &$subsub($msg,$h,$first_val));
 	        if (@hret > 1 or $hret[0]) {
                    @ret = ($first_val);
                    $do_croak=0;
                }
            }
	    if ($do_croak) {
  	        carp  $msg if $h->{PrintError};
	        croak $msg if $h->{RaiseError};
	    }
	}
	return (wantarray) ? @ret : $ret[0];
    } ];
    no strict qw(refs);
    my $code_ref = eval $method_code;
    *$method = eval $method_code;
    die "$@\n$method_code\n" if $@;
}

sub _setup_handle {
    my($h, $imp_class, $parent, $imp_data) = @_;

    if (ref($parent) =~ /^[^:]+::dr/){
        $h->STORE($_,$parent->{$_}) foreach (qw(Name Version Attribution));
    }
    #z SAVE DRIVER ATTRIBS FROM $drh
    if (0 and ref($h) =~ /^[^:]+::dr/ ) {
        for (qw(Name Version Attribution)) {
            $DBI::PurePerl::var->{Driver}->{$_} = $h->{$_} ;
        }
    }
    #z ADD DRIVER ATTRIBS TO $dbh
    if (0 and $DBI::PurePerl::var->{'Driver'} and ref($h) =~ /^[^:]+::db/ ){
        for (qw(Name Version Attribution)) {
            $h->{'Driver'}->{$_} = $DBI::PurePerl::var->{'Driver'}->{$_};
        }
        delete $DBI::PurePerl::var->{Driver};
    }
    $h->{"imp_data"} = $imp_data;
    $h->{"ImplementorClass"} = $imp_class;
    $h->{"Kids"} = $h->{"ActiveKids"} = 0;	# XXX not maintained
    $h->{"Active"} = 1;
    $h->{"FetchHashKeyName"} ||= $parent->{"FetchHashKeyName"} if $parent;
    $h->{"FetchHashKeyName"} ||= 'NAME';
    $h->{"PrintError"}=1 unless defined $h->{"PrintError"};
    $h->{"Taint"}=1 unless defined $h->{"Taint"};
    $h->{"Warn"} = 1 unless defined $h->{"Warn"};
    if (ref($parent) =~ /^[^:]+::db/){
        $h->STORE('RaiseError',$parent->{'RaiseError'});
        $h->STORE('PrintError',$parent->{'PrintError'});
        $h->STORE('HandleError',$parent->{'HandleError'});
        $h->STORE('Database',$parent);
        $parent->STORE('Statement',$h->{'Statement'}); #z but change on execute
    }
    #z
    #  THIS LINE DOES NOTHING EXCEPT KEEP THE HANDLE ALIVE.
    #  THERE IS NO OTHER REFERENCE TO frump  BUT IF YOU
    #  REMOVE IT examp.t ERRORS WILL NOT PROPOGATE TO $@
    #
    $DBI::PurePerl::frump = $h;
}
sub constant {
    warn "constant @_"; return;
}
sub trace {
    my ($h, $level, $file) = @_;
    my $old_level = $level;
    _set_trace_file($file);# if defined $file;
    if (defined $level) {
	$trace = $level;
	print $tfh "    DBI $DBI::VERSION (PurePerl) "
                . "dispatch trace level set to $level\n" if $level;
        if ($level==0 and fileno($tfh)) {
	    return _set_trace_file("");
        }
    }
    return $old_level;
}
sub _set_trace_file {
    my ($file) = @_;
    return unless defined $file;
    unless ($file) {
	open $tfh, ">&STDERR" or warn "Can't dup STDERR: $!";
	return 1;
    }
    open $tfh, ">>$file" or carp "Can't open $file: $!";
    select((select($tfh), $| = 1)[0]);
    return 1;
}
sub _get_imp_data {  shift->{"imp_data"}; }
sub _handles      {  my $h = shift;   return ($h,$h); }  #z :-)
sub _svdump       { }
sub dump_handle   { my $h = shift; warn join "\n", %$h; }

sub hash {
    my ($key, $type) = @_;
    my ($hash);
    if (!$type) {
        $hash = 0;
        # XXX The C version uses the "char" type, which could be either
        # signed or unsigned.  I use signed because so do the two
        # compilers on my system.
        for my $char (unpack ("c*", $key)) {
            $hash = $hash * 33 + $char;
        }
        $hash &= 0x7FFFFFFF;    # limit to 31 bits
        $hash |= 0x40000000;    # set bit 31
        return -$hash;          # return negative int
    }
    elsif ($type == 1) {	# Fowler/Noll/Vo hash
        # see http://www.isthe.com/chongo/tech/comp/fnv/
        require Math::BigInt;   # feel free to reimplement w/o BigInt!
	my $version = $Math::BigInt::VERSION || 0;
	if ($version >= 1.56) {
	    $hash = Math::BigInt->new(0x811c9dc5);
	    for my $uchar (unpack ("C*", $key)) {
		# multiply by the 32 bit FNV magic prime mod 2^64
		$hash = ($hash * 0x01000193) & 0xffffffff;
		# xor the bottom with the current octet
		$hash ^= $uchar;
	    }
	    # cast to int
	    return unpack "i", pack "i", $hash;
	}
	croak("DBI::PurePerl doesn't support hash type 1 without Math::BigInt >= 1.56 (available on CPAN)");
    }
    else {
        croak("bad hash type $type");
    }
}
sub looks_like_number {
    my @new = ();
    for my $thing(@_) {
        if (!defined $thing or $thing eq '') {
            push @new, undef;
        }
	elsif ( ($thing & ~ $thing) eq "0") { #z magic from Randal
            push @new, 1;
	}
        else {
	    push @new, 0;
	}
    }
    return (@_ >1) ? @new : $new[0];
}
sub neat {
    my $v = shift;
    return "undef" unless defined $v;
    return $v      if looks_like_number($v);
    my $maxlen = shift;
    if ($maxlen < length($v) + 2) {
	$v = substr($v,0,$maxlen-5);
	$v .= '...';
    }
    return "'$v'";
}

package DBI::var;              # ============ DBI::var

sub FETCH {
    my($key)=shift;
    return $DBI::err     if $$key eq '*err';
    return $DBI::errstr  if $$key eq '&errstr';
    if ($$key eq '"state'){
        my $state = $DBI::state;
        return $state if $state;
        return '' unless defined $state;
	$state= ($DBI::err) ? "S1000" : "00000" unless $state;
        return $state;
    }
    Carp::croak("FETCH $key not supported when using DBI::PurePerl");
}

package DBD::_::common;		# ============ DBD::_::common

sub trace {	# XXX should set per-handle level, not global
    my ($h, $level, $file) = @_;
    my $old_level = $level;
    if (defined $level) {
	$trace = $level;
	printf $tfh
            "    %s trace level set to %d in DBI $DBI::VERSION (PurePerl)\n",
	    $h, $level if $file;
    }
    _set_trace_file($file) if defined $file;
    return $old_level;
}
*debug = \&trace; *debug = \&trace; # twice to avoid typo warning

sub FETCH {
    my($h,$key)= @_;
    if (!$h->{$key} and $key =~ /^NAME_.c$/) {
        my $cols = $h->FETCH('NAME');
        return undef unless $cols;
        my @lcols = map { lc $_ } @$cols;
        $h->STORE('NAME_lc', \@lcols);
        my @ucols = map { uc $_ } @$cols;
        $h->STORE('NAME_uc',\@ucols);
        return $h->FETCH($key);
    }
    if (!$h->{$key} and $key =~ /^NAME.*_hash$/) {
        my $i=0;
        for my $c(@{$h->FETCH('NAME')}) {
            $h->{'NAME_hash'}->{$c}    = $i;
            $h->{'NAME_lc_hash'}->{"\L$c"} = $i;
            $h->{'NAME_uc_hash'}->{"\U$c"} = $i;
            $i++;
        }
    }
    return $h->{$key};
}
sub STORE {
    my ($h,$key,$value)= @_;
    $h->{$key} = $value;
}
sub err {
    my $h = shift;
    # XXX need to be shared between dbh and sth
    my $err = $h->{'err'} || $h->{'errstr'};
    $h->{'Database'}->{'err'} = $err if $h->{'Database'};
    return $err;
}
sub errstr {
    my $h = shift;
    my $errstr = $h->{'errstr'} || '';   # $h->{'err'}; caught in DBD-CSV
    $h->{'Database'}->{'errstr'} = $errstr if $h->{'Database'};
    return $errstr;
}
sub state {
    #z DOESN'T SEEM TO EVER BE CALLED
    my $h = shift;
    my $state = $h->{'state'};
    return $state if defined $state and $state eq '' and !$h->err;
    if (!$state) {
        $state= ($h->err) ? "S1000" : "00000";
    }
    $h->{'Database'}->{'state'} = $state if $h->{'Database'};
    return $state;
}
sub event {
    # do nothing
}
sub set_err {
    my($h,$errnum,$msg,$state,$method, $rv)=@_;
    $msg = $errnum unless defined $msg;
    if (my $dbh = $h->{'Database'}) {
	$dbh->{err} = $errnum;
	$dbh->{errstr} = $msg;
    }
    $DBI::errstr = $h->{errstr} = $msg;
    $DBI::state  = (defined $state) ? ($state eq "00000" ? "" : $state) : ($errnum ? "S1000" : "");
    $DBI::err    = $h->{err}    = $errnum;
    return $rv if $rv;
    return undef;
}
sub trace_msg {
    my($h,$msg,$minlevel)=@_;
    $minlevel = 1 unless defined $minlevel;
    $trace    = 0 unless defined $trace;
    return if $trace < $minlevel;
    print $tfh $msg;
    return 1;
}
sub private_data {
    warn "private_data @_";
}
sub rows {
    return -1; # always returns -1 here, see DBD::_::st::rows below
}
sub DESTROY {}

package DBD::_::st;		# ============ DBD::_::st

sub fetchrow_arrayref	{
    my $h = shift;
    # if we're here then driver hasn't implemented fetch/fetchrow_arrayref
    # so we assume they've implemented fetchrow_array and call that instead
    my @row = $h->fetchrow_array or return;
    return $h->_set_fbav(\@row);
}
# twice to avoid typo warning
*fetch = \&fetchrow_arrayref;  *fetch = \&fetchrow_arrayref;

sub fetchrow_array	{
    my $h = shift;
    # if we're here then driver hasn't implemented fetchrow_array
    # so we assume they've implemented fetch/fetchrow_arrayref
    my $row = $h->fetch or return;
    return @$row;
}
#z The DBI/t/* tests missed a typo on fetchrow
# twice to avoid typo warning
*fetchrow = \&fetchrow_array; *fetchrow = \&fetchrow_array;

sub fetchrow_hashref {
    my $h         = shift;
    my $row       = $h->fetch or return;
    my $FetchCase = shift;
    my $FetchHashKeyName = $FetchCase || $h->{'FetchHashKeyName'} || 'NAME';
    my $rowhash;
    @$rowhash{ @{$h->{$FetchHashKeyName}} } = @$row;
    return $rowhash;
}
sub dbih_setup_fbav {
    my $h = shift;
    return $h->{'_fbav'} || do {
        $DBI::PurePerl::var->{rows} = $h->{'_rows'} = 0;
        my $fields = $h->{'NUM_OF_FIELDS'}
                  or DBI::croak("NUM_OF_FIELDS not set");
        my @row = (undef) x $fields;
        \@row;
    };
}
sub _get_fbav {
    my $h = shift;
    my $av = $h->{'_fbav'} ||= dbih_setup_fbav($h);
    ++$h->{'_rows'};
    return $av;
}
sub _set_fbav {
    my $h = shift;
    my $fbav = $h->{'_fbav'} ||= dbih_setup_fbav($h);
    my $row = shift;
    if (my $bc = $h->{'_bound_cols'}) {
        for my $i (0..@$row-1) {
            my $bound = $bc->[$i];
            $fbav->[$i] = ($bound) ? ($$bound = $row->[$i]) : $row->[$i];
        }
    }
    else {
        @$fbav = @$row;
    }
    return $fbav;
}
sub bind_col {
    my ($h, $col, $value_ref,$from_bind_columns) = @_;
    $col-- unless $from_bind_columns; #z fix later
    DBI::croak("bind_col($col,$value_ref) needs a reference to a scalar")
	unless ref $value_ref eq 'SCALAR';
    my $fbav = $h->_get_fbav;
    $h->{'_bound_cols'}->[$col] = $value_ref;
    return 1;
}
sub bind_columns {
    my $h = shift;
    shift if !defined $_[0] or ref $_[0] eq 'HASH'; # old style args
    my $fbav = $h->_get_fbav;
    DBI::croak("bind_columns called with wrong number of args")
	if @_ != @$fbav;
    foreach (0..@_-1) {
        $h->bind_col($_, $_[$_],'from_bind_columns')
      }
    return 1;
}
sub finish {
    my $h = shift;
    $h->{'_rows'} = undef;
    $h->{'_fbav'} = undef;
    $h->{'Active'} = 0;
    return 1;
}
sub rows {
    my $h = shift;
    my $rows = $h->{'_rows'} || $DBI::PurePerl::var->{rows};
    return -1 unless defined $rows;
    return $rows;
}
1;
__END__

=pod

=head1 NAME

 DBI::PurePerl -- a DBI emulation using pure perl (no C/XS compilation required)

=head1 SYNOPSIS

 BEGIN { $ENV{DBI_PUREPERL} = 2 }
 use DBI;

=head1 DESCRIPTION

This is a pure perl emulation of the DBI internals.  In almost all
cases you will be better off using standard DBI since the portions
of the standard version written in C make it *much* *much* faster.

However, if you are in a situation where it isn't possible to install
a compiled version of standard DBI, and you're using pure-perl DBD drivers
then this module allows you to use most features of DBI without
needing any changes in your scripts.

=head1 USAGE

The usage is the same as for standard DBI with the exception
that you need to set the enviornment variable DBI_PUREPERL if
you want to use the PurePerl version.

 DBI_PUREPERL == 0 (the default) Always use compiled DBI, die
                   if it isn't properly compiled & installed

 DBI_PUREPERL == 1 Use compiled DBI if it is properly compiled
                   & installed, otherwise use PurePerl

 DBI_PUREPERL == 2 Always use PurePerl

You may set the enviornment variable in your shell (e.g. with
set or setenv or export, etc) or else set it in your script like
this:

 BEGIN { $ENV{DBI_PUREPERL}=2 }

before you C<use DBI;>.

=head1 INSTALLATION

In most situations simply install DBI (see the DBI pod for details).

In the situation in which you can not install DBI itself, you
may manually copy DBI.pm and PurePerl.pm into the appropriate
directories.

For example:

 cp DBI.pm      /usr/jdoe/mylibs/.
 cp PurePerl.pm /usr/jdoe/mylibs/DBI/.

Then add this to the top of scripts:

 BEGIN {
   $ENV{DBI_PUREPERL}=1;
   unshift @INC, '/usr/jdoe/mylibs';
 }

(Or should we perhaps patch Makefile.PL so that if DBI_PUREPERL
is set to 2 prior to make, the normal compile process is skipped
and the files are installed automatically?)

=head1 DIFFERENCES BETWEEN DBI AND DBI::PurePerl

=head2 Speed.  Speed.  Speed.  Did we mention speed?

DBI::PurePerl is slower. Although, with some drivers in some
contexts this may not be very significant for you.

By way of example... the test.pl script in the DBI source
distribution has a simple benchmark that just does:

    my $null_dbh = DBI->connect('dbi:NullP:','','');
    my $i = 10_000;
    $null_dbh->prepare('') while $i--;

In other words just prepares a statement, creating and destroying
a statement handle, over and over again.  Using the real DBI this
runs at ~4550 handles per second but DBI::PurePerl can only manage
~230 per second on the same machine.

I'm sure we can improve the performance with more work, but we'll
be lucky to more than double it.

=head2 May not fully support hash()

If you want to use type 1 hash, i.e., C<hash($string,1)> with
DBI::PurePerl, you'll need version 1.56 or higher of Math::BigInt
(available on CPAN).

=head2 Doesn't support preparse()

The DBI->preparse() method isn't supported in DBI::PurePerl.

=head2 Undoubtedly Others

Please let us know if you find any other differences between DBI
and DBI::PurePerl.

=head1 EXPERIMENTAL NATURE OF THIS RELEASE

This is the first CPAN release of DBI::PurePerl so please treat
it as experimental pending more extensive testing.  So far it
has passed all tests with DBD::CSV, DBD::AnyData, DBD::XBase,
DBD::Sprite, DBD::mysqlPP.  Please send bug reports to Jeff
Zucker at <jeff@vpservices.com> with a cc to <dbi-dev@perl.org>.

=head1 AUTHORS

Tim Bunce and Jeff Zucker.

Tim provided the direction and basis for the port as well as
cleaning things up.  The original idea for the module and most
of the brute force porting from C to perl were by Jeff.  Thanks
to Randal Schwartz and John Tobey for patches.

=head1 COPYRIGHT

Copyright (c) 2002  Tim Bunce  Ireland.

See COPYRIGHT section in DBI.pm for usage and distribution rights.

=cut
