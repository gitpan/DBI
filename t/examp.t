#!perl -Tw

use lib qw(blib/arch blib/lib);	# needed sin -T ignores PERL5LIB
use DBI qw(:sql_types);
use Config;
use Cwd;
$|=1;

my $haveFileSpec = eval { require File::Spec };

print "1..$tests\n";

require VMS::Filespec if $^O eq 'VMS';

sub ok ($$;$) {
    my($n, $ok, $msg) = @_;
	$msg = ($msg) ? " ($msg)" : "";
    ++$t;
    die "sequence error, expected $n but actually $t at line ".(caller)[2]."\n"
		if $n and $n != $t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    warn "# failed test $t at line ".(caller)[2]."$msg\n" unless $ok;
    return $ok;
}
	

my $r;
my $dbh = DBI->connect('dbi:ExampleP(AutoCommit=>1 ,Taint = 1):', '', '');
die "Unable to connect to ExampleP driver: $DBI::errstr" unless $dbh;

my $dbh2 = DBI->connect('dbi:ExampleP:', '', '');
ok(0, $dbh != $dbh2);
my $dbh3 = DBI->connect_cached('dbi:ExampleP:', '', '');
my $dbh4 = DBI->connect_cached('dbi:ExampleP:', '', '');
ok(0, $dbh3 == $dbh4);
my $dbh5 = DBI->connect_cached('dbi:ExampleP:', '', '', { foo=>1 });
ok(0, $dbh5 != $dbh4);

$dbh->{AutoCommit} = 1;
$dbh->{PrintError} = 0;
ok(0, $dbh->{Taint}      == 1);
ok(0, $dbh->{AutoCommit} == 1);
ok(0, $dbh->{PrintError} == 0);
#$dbh->trace(2);

ok(0, $dbh->ping);
ok(0, $dbh->quote("quote's") eq "'quote''s'");
ok(0, $dbh->quote("42", SQL_VARCHAR) eq "'42'");
ok(0, $dbh->quote("42", SQL_INTEGER) eq "42");
ok(0, $dbh->quote(undef)     eq "NULL");

eval { $dbh->commit('dummy') };
ok(0, $@ =~ m/^DBI commit: invalid number of parameters: handle \+ 1/);

my $cursor_e = $dbh->prepare("select unknown_field_name from ?");
ok(0, !defined $cursor_e);
ok(0, $DBI::err);
ok(0, $DBI::errstr =~ m/unknown_field_name/);
ok(0, $DBI::err    == $dbh->err);
ok(0, $DBI::errstr eq $dbh->errstr);

ok(0, $dbh->errstr eq $dbh->func('errstr'));

foreach(17..19) { ok(0, 1) }	# soak up to next round number

my $std_sql = "select mode,size,name from ?";
my $csr_a = $dbh->prepare($std_sql);
ok(0, ref $csr_a);
my $csr_b = $dbh->prepare($std_sql);
ok(0, ref $csr_b);

ok(0, $csr_a != $csr_b);
ok(0, $csr_a->{NUM_OF_FIELDS} == 3);
ok(0, $csr_a->{'Database'}->{'Driver'}->{'Name'} eq 'ExampleP');

ok(0, "@{$csr_b->{NAME_lc}}" eq "mode size name");	# before NAME
ok(0, "@{$csr_b->{NAME_uc}}" eq "MODE SIZE NAME");
ok(0, "@{$csr_b->{NAME}}"    eq "mode size name");

# get a dir always readable on all platforms
my $dir = getcwd() || cwd();
$dir = VMS::Filespec::unixify($dir) if $^O eq 'VMS';
my($col0, $col1, $col2);
my(@row_a, @row_b);

#$csr_a->trace(2);
ok(0, $csr_a->bind_columns(undef, \($col0, $col1, $col2)) );
ok(0, $csr_a->{Taint} = 1);
ok(0, $csr_a->execute( $dir ));

@row_a = $csr_a->fetchrow_array;
ok(0, @row_a);

# check bind_columns
ok(0, $row_a[0] eq $col0);
ok(0, $row_a[1] eq $col1);
ok(0, $row_a[2] eq $col2);

# Check Taint attribute works. This requires this test to be run
# manually with the -T flag: "perl -T -Mblib t/examp.t"
sub is_tainted {
	my $foo;
    return ! eval { ($foo=join('',@_)), kill 0; 1; };
}
if (is_tainted($^X)) {
    print "Taint attribute test enabled\n";
    ok(0, is_tainted($row_a[0]) );
    ok(0, is_tainted($row_a[1]) );
    ok(0, is_tainted($row_a[2]) );
	# check simple method call values
    ok(0, 1);
	# check simple attribute values
    ok(0, 1); # is_tainted($dbh->{AutoCommit}) );
	# check nested attribute values (where a ref is returned)
    #ok(0, is_tainted($csr_a->{NAME}->[0]) );
	# check checking for tainted values
	eval { $dbh->prepare("tainted sql $^X"); 1; };
	ok(0, $@ =~ /Insecure dependency/, $@);
}
else {
    print "Taint attribute tests skipped\n";
    ok(0,1) while (1..6);
}
$csr_a->{Taint} = 0;

ok(0, $csr_b->bind_param(1, $dir));
ok(0, $csr_b->execute());
@row_b = @{ $csr_b->fetchrow_arrayref };
ok(0, @row_b);

ok(0, "@row_a" eq "@row_b");
@row_b = $csr_b->fetchrow_array;
ok(0, "@row_a" ne "@row_b");

ok(0, $csr_a->finish);
ok(0, $csr_b->finish);

ok(0, $csr_b->execute());
my $row_b = $csr_b->fetchrow_hashref('NAME_uc');
ok(0, $row_b);
ok(0, $row_b->{MODE} == $row_a[0]);
ok(0, $row_b->{SIZE} == $row_a[1]);
ok(0, $row_b->{NAME} eq $row_a[2]);

$csr_a = undef;	# force destruction of this cursor now
ok(0, 1);

ok(0, $csr_b->execute());
$r = $csr_b->fetchall_arrayref;
ok(0, $r);
ok(0, @$r);
ok(0, $r->[0]->[0] == $row_a[0]);
ok(0, $r->[0]->[1] == $row_a[1]);
ok(0, $r->[0]->[2] eq $row_a[2]);

ok(0, $csr_b->execute());
$r = $csr_b->fetchall_arrayref([2,1]);
ok(0, $r && @$r);
ok(0, $r->[0]->[1] == $row_a[1]);
ok(0, $r->[0]->[0] eq $row_a[2]);

ok(0, $csr_b->execute());
$r = $csr_b->fetchall_arrayref({ Size=>1, NAME=>1});
ok(0, $r && @$r);
ok(0, $r->[0]->{Size} == $row_a[1]);
ok(0, $r->[0]->{NAME} eq $row_a[2]);

@row_b = $dbh->selectrow_array($std_sql, undef, $dir);
ok(0, @row_b == 3);
ok(0, "@row_b" eq "@row_a");
$r = $dbh->selectall_arrayref($std_sql, undef, $dir);
ok(0, $r);
ok(0, @{$r->[0]} == 3);
ok(0, "@{$r->[0]}" eq "@row_a");

# ---

my $csr_c;
$csr_c = $dbh->prepare("select unknown_field_name1 from ?");
ok(0, !defined $csr_c);
ok(0, $DBI::errstr =~ m/Unknown field names: unknown_field_name1/);

$dbh->{RaiseError} = 1;
ok(0, $dbh->{RaiseError});
ok(0, ! eval { $csr_c = $dbh->prepare("select unknown_field_name2 from ?"); 1; });
#print "$@\n";
ok(0, $@ =~ m/Unknown field names: unknown_field_name2/);
$dbh->{RaiseError} = 0;
ok(0, !$dbh->{RaiseError});

{
  my @warn;
  local($SIG{__WARN__}) = sub { push @warn, @_ };
  $dbh->{PrintError} = 1;
  ok(0, $dbh->{PrintError});
  ok(0, ! $dbh->prepare("select unknown_field_name3 from ?"));
  ok(0, "@warn" =~ m/Unknown field names: unknown_field_name3/);
  $dbh->{PrintError} = 0;
  ok(0, !$dbh->{PrintError});
}

ok(0, $csr_a = $dbh->prepare($std_sql));
ok(0, $csr_a->execute('/'));
my $dump_file = ($ENV{TMP} || $ENV{TEMP} || "/tmp")."/dumpcsr.tst";
if (open(DUMP_RESULTS, ">$dump_file")) {
	ok(0, $csr_a->dump_results("4", "\n", ",\t", \*DUMP_RESULTS));
	close(DUMP_RESULTS);
	ok(0, -s $dump_file > 0);
} else {
	warn "# dump_results test skipped: unable to open $dump_file: $!\n";
	ok(0, 1);
	ok(0, 1);
}
#unlink $dump_file;


# Test the table_info method
# First generate a list of all subdirectories
$dir = $haveFileSpec ? File::Spec->curdir() : ".";
ok(0, opendir(DIR, $dir));
my(%dirs, %unexpected, %missing);
while (defined(my $file = readdir(DIR))) {
    $dirs{$file} = 1 if -d $file;
}
close(DIR);
my $sth = $dbh->table_info();
ok(0, $sth);
%unexpected = %dirs;
%missing = ();
while (my $ref = $sth->fetchrow_hashref()) {
    if (exists($unexpected{$ref->{'TABLE_NAME'}})) {
	delete $unexpected{$ref->{'TABLE_NAME'}};
    } else {
	$missing{$ref->{'TABLE_NAME'}} = 1;
    }
}
ok(0, keys %unexpected == 0)
    or print "Unexpected directories: ", join(",", keys %unexpected), "\n";
ok(0, keys %missing == 0)
    or print "Missing directories: ", join(",", keys %missing), "\n";

# Test the tables method
%unexpected = %dirs;
%missing = ();
foreach my $table ($dbh->tables()) {
    if (exists($unexpected{$table})) {
	delete $unexpected{$table};
    } else {
	$missing{$table} = 1;
    }
}
ok(0, keys %unexpected == 0)
    or print "Unexpected directories: ", join(",", keys %unexpected), "\n";
ok(0, keys %missing == 0)
    or print "Missing directories: ", join(",", keys %missing), "\n";


# Test the fake directories.
print "Testing the fake directories.\n";
for (my $i = 0;  $i < 300;  $i += 10) {
    ok(0, $csr_a = $dbh->prepare("SELECT * FROM long_list_$i"));
    ok(0, $csr_a->execute());
    my $ok = 1;
    my $j = $i;
    my $ref;
    while (--$j >= 0) {
	if (!($ref = $csr_a->fetchrow_hashref())
	    ||  $ref->{'name'} ne "file$j") {
	    $ok = 0;
	    last;
	}
    }
    $ok = 0 if $csr_a->fetchrow_hashref();
    ok(0, $ok);
}

DBI->disconnect_all;	# doesn't do anything yet
ok(0, 1);

# Test the $dbh->func method
print "Testing \$dbh->func().\n";
my %tables = map { $_ =~ /lib/ ? ($_, 1) : () } $dbh->tables();
my $ok = 1;
foreach my $t ($dbh->func('lib', 'examplep_tables')) {
    defined(delete $tables{$t}) or print "Unexpected table: $t\n";
}
ok(0, (%tables == 0));

BEGIN { $tests = 186; }
