package DBI::Profile;

=head1 NAME

DBI::Profile - Performance profiling and benchmarking for the DBI

=head1 SYNOPSIS

The easiest way to enable DBI profiling is to set the DBI_PROFILE
environment variable to 2 and then run your code as usual:

  DBI_PROFILE=2 prog.pl

This will profile your program and then output a textual summary
grouped by query.  You can also enable profiling by setting the
Profile attribute of any DBI handle:

  $dbh->{Profile} = 2;

Other values are possible - see L<"ENABLING A PROFILE"> below.

=head1 DESCRIPTION

DBI::Profile is new and experimental and subject to change.

The DBI::Profile module provides a simple interface to collect and
report performance and benchmarking data from the DBI.

For a more elaborate interface, suitable for larger programs, see
L<DBI::ProfileDumper|DBI::ProfileDumper> and L<dbiprof|dbiprof>.
For Apache/mod_perl applications see
L<DBI::ProfileDumper::Apache|DBI::ProfileDumper::Apache>.

=head1 OVERVIEW

Performance data collection for the DBI is built around several
concepts which are important to understand clearly.

=over 4

=item Method Dispatch

Every method call on a DBI handle passes through a single 'dispatch'
function which manages all the common aspects of DBI method calls,
such as handling the RaiseError attribute.

=item Data Collection

If profiling is enabled for a handle then the dispatch code takes
a high-resolution timestamp soon after it is entered. Then, after
calling the appropriate method and just before returning, it takes
another high-resolution timestamp and calls a function to record
the information.  That function is passed the two timestamps
plus the DBI handle and the name of the method that was called.
That information about a single DBI method call is called the
I<profile sample> data.

=item Data Filtering

If the method call was invoked by the DBI or by a driver then the
call is currently ignored for profiling because the time spent will
be accounted for by the original 'outermost' call.

For example, the calls that the selectrow_arrayref() method makes
to prepare() and execute() etc. are not counted individually
because the time spent in those methods is going to be allocated
to the selectrow_arrayref() method when it returns. If this was not
done then it would be very easy to double count time spent inside
the DBI.

In future releases it may be possible to alter this behaviour.

=item Data Storage Tree

The profile data is stored as 'leaves on a tree'. The 'path' through
the branches of the tree to the particular leaf that will store the
profile sample data for a profiled call is determined dynamically.
This is a powerful feature.

For example, if the Path is

  [ 'foo', 'bar', 'baz' ]

then the new profile sample data will be I<merged> into the tree at

  $h->{Profile}->{Data}->{foo}->{bar}->{baz}

It wouldn't be very useful to merge all the call data into one leaf
node (except to get an overall 'time spent inside the DBI' total).
It's more common to want the Path to include the current statement
text and/or the name of the method called to show what the time
spent inside the DBI was for.

The Path can contain some 'magic cookie' values that are automatically
replaced by corresponding dynamic values when they're used.
For example DBIprofile_Statement (exported by DBI::profile) is
automatically replaced by value of the C<Statement> attribute of
the handle. For example, is the Path was:

  [ 'foo', DBIprofile_Statement, 'bar' ]

and the value of $h->{Statement} was:

  SELECT * FROM tablename

then the profile data will be merged into the tree at:

  $h->{Profile}->{Data}->{foo}->{SELECT * FROM tablename}->{bar}

The default Path is just C<[ DBIprofile_Statement ]> and so by
default the profile data is aggregated per distinct Statement string.

For statement handles this is always simply the string that was
given to prepare() when the handle was created.  For database handles
this is the statement that was last prepared or executed on that
database handle. That can lead to a little 'fuzzyness' because, for
example, calls to the quote() method to build a new statement will
typically be associated with the previous statement. In practice
this isn't a significant issue and the dynamic Path mechanism can
be used to setup your own rules.

=item Profile Data

Profile data is stored at the 'leaves' of the tree as references
to an array of numeric values. For example:

    [
      106,                    # count
      0.0312958955764771,     # total duration
      0.000490069389343262,   # first duration
      0.000176072120666504,   # shortest duration
      0.00140702724456787,    # longest duration
      1023115819.83019,       # time of first event
      1023115819.86576,       # time of last event
    ]

=back

=head1 ENABLING A PROFILE

Profiling is enabled for a handle by assigning to the Profile
attribute. For example:

  $h->{Profile} = DBI::Profile->new();

The Profile attribute holds a blessed reference to a hash object
that contains the profile data and attributes relating to it.
The class the Profile object is blessed into is expected to
provide at least a DESTROY method which will dump the profile data
to the DBI trace file handle (STDERR by default).

All these examples have the same effect as the first:

  $h->{Profile} = {};
  $h->{Profile} = "DBI::Profile";
  $h->{Profile} = "2/DBI::Profile";
  $h->{Profile} = 2;

If a non-blessed hash reference is given then the DBI::Profile
module is automatically C<require>'d and the reference is blessed
into that class.

If a string is given then it is split on 'C</>' characters and the
first value is used to select the Path to be used (see below).
The second value, if present, is used as the name of a module which
will be loaded and it's C<new> method called. If not present it
defaults to DBI::Profile. Any other values are passed as arguments
to the C<new> method. For example: "C<2/DBIx::OtherProfile/Foo/42>".

Various common sequences for Path can be selected by simply assigning
an integer value to Profile. The simplest way to explain how the
values are interpreted is to show the code:

    push @Path, "DBI"                       if $path & 0x01;
    push @Path, DBIprofile_Statement        if $path & 0x02;
    push @Path, DBIprofile_MethodName       if $path & 0x04;
    push @Path, DBIprofile_MethodClass      if $path & 0x08;

So using the value "C<1>" causes all profile data to be merged into
a single leaf of the tree. That's useful when you just want a total.

Using "C<2>" causes profile sample data to be merged grouped by
the corresponding Statement text. This is the most frequently used.

Using "C<4>" causes profile sample data to be merged grouped by
the method name ('FETCH', 'prepare' etc.). Using "C<8>" is similar
but gives the fully qualified 'glob name' of the method called. For
example: '*DBD::Driver::db::prepare', '*DBD::_::st::fetchrow_hashref'.

The values can be added together to create deeper paths. The most
useful being 6 (statement then method name) or 10 (statement then
method name with class).  Using a negative number will reverse the
path. Thus -6 will group by method name then statement.

The spliting and parsing of string values assigned to the Profile
attribute may seem a little odd, but there's a good reason for it.
Remember that attributes can be embedded in the Data Source Name
string which can be passed in to a script as a parameter. For
example:

    dbi:DriverName(RaiseError=>1,Profile=>2):dbname

And also, if the C<DBI_PROFILE> environment variable is set then
The DBI arranges for every driver handle to share the same profile
object. When perl exits a single profile summary will be generated
that reflects (as nearly as practical) the total use of the DBI by
the application.


=head1 THE PROFILE OBJECT

The DBI core expects the Profile attribute value to be a hash
reference and if the following values don't exist it will create
them as needed:

=head2 Data

A reference to a hash containing the collected profile data.

=head2 Path

The Path value is used to control where the profile for a method
call will be merged into the collected profile data.  Whenever
profile data is to be stored the current value for Path is used.

The value can be one of:

=over 4

=item Array Reference

Each element of the array defines an element of the path to use to
store the profile data into the C<Data> hash.

=item Undefined value (the default)

Treated the same as C<[ $DBI::Profile::DBIprofile_Statement ]>.

=item Subroutine Reference B<NOT YET IMPLEMENTED>

The subroutine is passed the DBI method name and the handle it was
called on.  It should return a list of values to uses as the path.
If it returns an empty list then the method call is not profiled.

=back

The following 'magic cookie' values can be included in the Path and will be

=over 4

=item DBIprofile_Statement

Replaced with the current value of the Statement attribute for the
handle the method was called with. If that value is undefined then
an empty string is used.

=item DBIprofile_MethodName

Replaced with the name of the DBI method that the profile sample
relates to.

=item DBIprofile_MethodClass

Replaced with the fully qualified name of the DBI method, including
the package, that the profile sample relates to. This shows you
where the method was implemented. For example:

  'DBD::_::db::selectrow_arrayref' =>
      0.022902s
  'DBD::mysql::db::selectrow_arrayref' =>
      2.244521s / 99 = 0.022445s avg (first 0.022813s, min 0.022051s, max 0.028932s)

The "DBD::_::db::selectrow_arrayref" shows that the driver has
inherited the selectrow_arrayref method provided by the DBI.

But you'll note that there is only one call to
DBD::_::db::selectrow_arrayref but another 99 to
DBD::mysql::db::selectrow_arrayref. That's because after the first
call Perl has cached the method to speed up method calls.
You may also see some names begin with an asterix ('C<*>').
Both of these effects are subject to change in later releases.


=back

Other magic cookie values may be added in the future.


=head1 REPORTING

=head2 Report Format

The current profile data can be formatted and output using

    print $h->{Profile}->format;

To discard the profile data and start collecting fresh data
you can do:

    $h->{Profile}->{Data} = undef;


The default results format looks like this:

  DBI::Profile: 0.001015 seconds (5 method calls) programname
  '' =>
      0.000024s / 2 = 0.000012s avg (first 0.000015s, min 0.000009s, max 0.000015s)
  'SELECT mode,size,name FROM table' =>
      0.000991s / 3 = 0.000330s avg (first 0.000678s, min 0.000009s, max 0.000678s)

Which shows the total time spent inside the DBI, with a count of
the total number of method calls and the name of the script being
run, then a formated version of the profile data tree.

If the results are being formated when the perl process is exiting
(which is usually the case when the DBI_PROFILE environment variable
is used) then the percentage of time the process spent inside the
DBI is also shown.

In the example above the paths in the tree are only one level deep and
use the Statement text as the value (that's the default behaviour).

The merged profile data at the 'leaves' of the tree are presented
as total time spent, count, average time spent (which is simply total
time divided by the count), then the time spent on the first call,
the time spent on the fastest call, and finally the time spent on
the slowest call.

The 'avg', 'first', 'min' and 'max' times are not particularly
useful when the profile data path only contains the statement text.
Here's an extract of a more detailed example using both statement
text and method name in the path:

  'SELECT mode,size,name FROM table' =>
      'FETCH' =>
          0.000076s
      'fetchrow_hashref' =>
          0.036203s / 108 = 0.000335s avg (first 0.000490s, min 0.000152s, max 0.002786s)

Here you can see the 'avg', 'first', 'min' and 'max' for the
108 calls to fetchrow_hashref() become rather more interesting.
Also the data for FETCH just shows a time value because it was only
called once.

Currently the profile data is output sorted by branch names. That
may change in a later version so the leaf nodes are sorted by total
time per leaf node.


=head2 Report Destination

The default method of reporting is for the DESTROY method of the
Profile object to format the results and write them using:

    DBI->trace_msg($results, 0)

to write them to the DBI trace() filehandle (which defaults to
STDERR). To direct the DBI trace filehandle to write to a file
without enabling tracing the trace() method can be called with a
trace level of 0. For example:

    DBI->trace(0, $filename);

The same effect can be achieved without changing the code by
setting the C<DBI_TRACE> environment variable to C<0=filename>.


=head1 CHILD HANDLES

Child handles inherit a reference to the Profile attribute value
of their parent.  So if profiling is enabled for a database handle
then by default the statement handles created from it all contribute
to the same merged profile data tree.


=head1 CUSTOM DATA COLLECTION

=head2 Using The Path Attribute

  XXX example to be added later using a selectall_arrayref call
  XXX nested inside a fetch loop where the first column of the
  XXX outer loop is bound to the profile Path using
  XXX bind_column(1, \${ $dbh->{Profile}->{Path}->[0] })
  XXX so you end up with separate profiles for each loop
  XXX (patches welcome to add this to the docs :)

=head2 Adding Your Own Samples

The dbi_profile() function can be used to add extra sample data
into the profile data tree. For example:

    use DBI;
    use DBI::Profile (dbi_profile dbi_time);

    my $t1 = dbi_time(); # floating point high-resolution time

    ... execute code you want to profile here ...

    my $t2 = dbi_time();
    dbi_profile($h, $statement, $method, $t1, $t2);

The $h parameter is the handle the extra profile sample should be
associated with. The $statement parameter is the string to use where
the Path specifies DBIprofile_Statement. If $statement is undef
then $h->{Statement} will be used. Similarly $method is the string
to use if the Path specifies DBIprofile_MethodName. There is no
default value for $method.

The $h->{Profile}{Path} attribute is processed by dbi_profile() in
the usual way.

It is recommended that you keep these extra data samples separate
from the DBI profile data samples by using values for $statement
and $method that are distinct from any that are likely to appear
in the profile data normally.


=head1 SUBCLASSING

Alternate profile modules must subclass DBI::Profile to help ensure
they work with future versions of the DBI.


=head1 CAVEATS

Applications which generate many different statement strings
(typically because they don't use placeholders) and profile with
DBIprofile_Statement in the Path (the default) will consume memory
in the Profile Data structure for each statement.

If a method throws an exception itself (not via RaiseError) then
it won't be counted in the profile.

If a HandleError subroutine throws an exception (rather than returning
0 and letting RaiseError do it) then the method call won't be counted
in the profile.

Time spent in DESTROY is added to the profile of the parent handle.

Time spent in DBI->*() methods is not counted. The time spent in
the driver connect method, $drh->connect(), when it's called by
DBI->connect is counted if the DBI_PROFILE environment variable is set.

Time spent fetching tied variables, $DBI::errstr, is counted.

DBI::PurePerl does not support profiling (though it could in theory).

A few platforms don't support the gettimeofday() high resolution
time function used by the DBI (and available via the dbi_time() function).
In which case you'll get integer resolution time which is mostly useless.

On Windows platforms the dbi_time() function is limited to millisecond
resolution. Which isn't sufficiently fine for our needs, but still
much better than integer resolution. This limited resolution means
that fast method calls will often register as taking 0 time. And
timings in general will have much more 'jitter' depending on where
within the 'current millisecond' the start and and timing was taken.

This documentation could be more clear. Probably needs to be reordered
to start with several examples and build from there.  Trying to
explain the concepts first seems painful and to lead to just as
many forward references.  (Patches welcome!)

=cut


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter ();
use UNIVERSAL ();
use Carp;

use DBI qw(dbi_time dbi_profile dbi_profile_merge);

$VERSION = sprintf "%d.%02d", '$Revision: 1.6 $ ' =~ /(\d+)\.(\d+)/;

@ISA = qw(Exporter);
@EXPORT = qw(
    DBIprofile_Statement
    DBIprofile_MethodName
    DBIprofile_MethodClass
    dbi_profile
    dbi_profile_merge
    dbi_time
);
@EXPORT_OK = qw(
    format_profile_thingy
);

use constant DBIprofile_Statement	=> -2100000001;
use constant DBIprofile_MethodName	=> -2100000002;
use constant DBIprofile_MethodClass	=> -2100000003;


sub new {
    my $class = shift;
    my $profile = { @_ };
    return bless $profile => $class;
}


sub _auto_new {
    my $class = shift;
    my ($arg) = @_;

    # This sub is called by DBI internals when a non-hash-ref is
    # assigned to the Profile attribute. For example
    #	dbi:mysql(RaiseError=>1,Profile=>4/DBIx::MyProfile):dbname
    # This sub works out what to do and returns a suitable hash ref.
    
    my ($path, $module, @args);

    # parse args
    if ($arg =~ m!/!) {
        # it's a path/module/arg/arg/arg list
        ($path, $module, @args) = split /\s*\/\s*/, $arg, -1;
    } elsif ($arg =~ /^\d+$/) {
        # it's a numeric path selector
        $path = $arg;
    } else {
        # it's a module name
        $module = $arg;
    }

    my @Path;
    if ($path) {
	my $reverse = ($path < 0) ? ($path=-$path, 1) : 0;
	push @Path, "DBI"			if $path & 0x01;
	push @Path, DBIprofile_Statement	if $path & 0x02;
	push @Path, DBIprofile_MethodName	if $path & 0x04;
	push @Path, DBIprofile_MethodClass	if $path & 0x08;
	@Path = reverse @Path if $reverse;
    } else {
        # default Path
        push @Path, DBIprofile_Statement;
    }

    if ($module) {
	if (eval "require $module") {
	  $class = $module;
	}
	else {
	    carp "Can't use $module for DBI profile: $@";
	}
    }

    return $class->new(Path => \@Path, @args);
}


sub format {
    my $self = shift;
    my $class = ref($self) || $self;
    
    my $prologue = "$class: ";
    my $detail = $self->format_profile_thingy(
	$self->{Data}, 0, "    ",
	my $path = [],
	my $leaves = [],
    )."\n";

    if (@$leaves) {
	dbi_profile_merge(my $totals=[], @$leaves);
	my ($count, $dbi_time) = @$totals;
	(my $progname = $0) =~ s:.*/::;
	if ($count) {
	    $prologue .= sprintf "%f seconds ", $dbi_time;
	    my $perl_time = dbi_time() - $^T;
	    $prologue .= sprintf "%.2f%% ", $dbi_time/$perl_time*100
		if $DBI::PERL_ENDING && $perl_time;
	    $prologue .= sprintf "(%d method calls) $progname\n", $count;
	}

	if (@$leaves == 1 && $self->{Data}->{DBI}) {
	    $detail = "";	# hide it
	}
    }
    return ($prologue, $detail) if wantarray;
    return $prologue.$detail;
}


sub format_profile_leaf {
    my ($self, $thingy, $depth, $pad, $path, $leaves) = @_;
    croak "format_profile_leaf called on non-leaf ($thingy)"
	unless UNIVERSAL::isa($thingy,'ARRAY');

    push @$leaves, $thingy if $leaves;
    if (0) {
	use Data::Dumper;
	return Dumper($thingy);
    }
    my ($count, $total_time, $first_time, $min, $max, $first_called, $last_called) = @$thingy;
    return sprintf "%s%fs\n", ($pad x $depth), $total_time
	if $count <= 1;
    return sprintf "%s%fs / %d = %fs avg (first %fs, min %fs, max %fs)\n",
	($pad x $depth), $total_time, $count, $count ? $total_time/$count : 0,
	$first_time, $min, $max;
}


sub format_profile_branch {
    my ($self, $thingy, $depth, $pad, $path, $leaves) = @_;
    croak "format_profile_branch called on non-branch ($thingy)"
	unless UNIVERSAL::isa($thingy,'HASH');
    my @chunk;
    my @keys = sort keys %$thingy;
    while ( @keys ) {
	my $k = shift @keys;
	my $v = $thingy->{$k};
	push @$path, $k;
	push @chunk, sprintf "%s'%s' =>\n%s",
	    ($pad x $depth), $k,
	    $self->format_profile_thingy($v, $depth+1, $pad, $path, $leaves);
	pop @$path;
    }
    return join "", @chunk;
}


sub format_profile_thingy {
    my ($self, $thingy, $depth, $pad, $path, $leaves) = @_;
    return $self->format_profile_leaf(  $thingy, $depth, $pad, $path, $leaves)
	if UNIVERSAL::isa($thingy,'ARRAY');
    return $self->format_profile_branch($thingy, $depth, $pad, $path, $leaves)
	if UNIVERSAL::isa($thingy,'HASH');
    return "$thingy\n";
}


sub on_destroy {
    my $self = shift;
    my $detail = $self->format() if $self->{Data};
    DBI->trace_msg($detail, 0) if $detail;
}

sub DESTROY {
    my $self = shift;
    eval { $self->on_destroy };
    if ($@) {
        my $class = ref($self) || $self;
        DBI->trace_msg("$class on_destroy failed: $@", 0);
    }
}

1;

