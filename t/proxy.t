# -*- perl -*-

$| = 1;

# Can we load the modules? If not, exit the test immediately:
# Reason is most probable a missing prerequisite.
#
# Is syslog available (required for the server)?

eval {
    local $SIG{__WARN__} = sub { $@ = shift };
    require DBD::Proxy;
    require DBI::ProxyServer;
    require Sys::Syslog;
    if (defined(&Sys::Syslog::setlogsock)  &&
	defined(&Sys::Syslog::_PATH_LOG)) {
        Sys::Syslog::setlogsock('unix');
    }
    Sys::Syslog::openlog('proxy.t', '', 'daemon');
    Sys::Syslog::syslog('debug', "Trying syslog availability.");
};
if ($@) { print "1..0\n"; print $@; exit 0; }

# Is syslog available? (Required for the server)
my $port = 12345; # XXX this should be a dynamically chosen free port

my @args = ("--port=$port", '--debug', '--nofork', '--timeout=20');
push @args, "--stderr" if -t STDOUT; # not running under Test::Harness

if (@ARGV) {			# For debugging we need a possibility to
    if ($ARGV[0] eq 'server') { # separate server and client
	DBI::ProxyServer::main(@args);
	exit(0);
    }
}
else {
    # Is fork() available? If not, skip this test.
    my $pid;
    eval {
	$pid = fork();
	if (defined($pid)) {
	    if (!$pid) {
		DBI::ProxyServer::main(@args);
		exit(0);
	    }
	}
    };

    if (!$pid) {
	print "1..0\n";
	exit 0;
    }
    $SIG{'CHLD'} = sub { wait };
    sleep 5;
}

END { if ($pid) { kill 1, $pid; } };


use DBI;
use Config;
use Cwd;
$|=1;

print "1..$tests\n";

require VMS::Filespec if $^O eq 'VMS';

sub ok ($$) {
    my($n, $ok) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
		if $n and $n != $t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    warn "# failed test $t at line ".(caller)[2]."\n" unless $ok;
    $ok;
}
	
my $dbh = DBI->connect(
	"DBI:Proxy:hostname=127.0.0.1;port=$port;debug=1;dsn=DBI:ExampleP:",
	'', '', { 'PrintError' => 0 }
);
ok(0, $dbh);
if (!$dbh) {
    print "Connect error: ", $DBI::errstr, "\n";
} else {
    print "dbh = $dbh\n";
}
$dbh->{AutoCommit} = 1;
#$dbh->trace(2);

ok(0, $dbh->ping);
ok(3, $dbh->quote("quote's") eq "'quote''s'");
ok(0, $dbh->quote(undef)     eq "NULL");

eval { $dbh->commit('dummy') };
ok(0, $@ =~ m/^DBI commit: invalid number of parameters: handle \+ 1/);

my $cursor_e = $dbh->prepare("select unknown_field_name from ?");
ok(0, defined $cursor_e);
ok(0, !$cursor_e->execute('a'));
ok(0, $DBI::err);
ok(0, $DBI::errstr =~ m/unknown_field_name/);
ok(0, $DBI::err    == $dbh->err);
ok(0, $DBI::errstr eq $dbh->errstr);

ok(0, $dbh->errstr eq $dbh->func('errstr'));

foreach(13..19) { ok(0, 1) }	# soak up to next round number

my $dir = cwd();	# a dir always readable on all platforms
$dir = VMS::Filespec::unixify($dir) if $^O eq 'VMS';

my $csr_a = $dbh->prepare("select mode,size,name from ?");
ok(20, ref $csr_a);
ok(0, $csr_a->execute($dir));

my $csr_b = $dbh->prepare("select mode,size,name from ?");
ok(0, ref $csr_b);
ok(0, $csr_b->execute($dir));

ok(0, $csr_a != $csr_b);
ok(0, $csr_a->{NUM_OF_FIELDS} == 3);
ok(0, $csr_a->{'Database'}->{'Driver'}->{'Name'} eq 'Proxy');

my($col0, $col1, $col2);
my(@row_a, @row_b);

#$csr_a->trace(2);
ok(27, $csr_a->bind_columns(undef, \($col0, $col1, $col2)) );
ok(0, $csr_a->execute($dir));
@row_a = $csr_a->fetchrow_array;
ok(0, @row_a);
# check bind_columns
ok(0, $row_a[0] eq $col0);
ok(0, $row_a[1] eq $col1);
ok(0, $row_a[2] eq $col2);

ok(0, $csr_b->bind_param(1, $dir));
ok(0, $csr_b->execute());
@row_b = @{ $csr_b->fetchrow_arrayref };
ok(0, @row_b);

ok(36, "@row_a" eq "@row_b");
@row_b = $csr_b->fetchrow_array;
ok(37, "@row_a" ne "@row_b")
    or printf("Expected something different from '%s', got '%s'\n", "@row_a",
              "@row_b");

ok(0, $csr_a->finish);
ok(0, $csr_b->finish);

ok(0, $csr_b->execute());
my $row_b = $csr_b->fetchrow_hashref;
ok(0, $row_b);
ok(0, $row_b->{mode} == $row_a[0]);
ok(0, $row_b->{size} == $row_a[1]);
ok(0, $row_b->{name} eq $row_a[2]);

$csr_a = undef;	# force destructin of this cursor now
ok(45, 1);

ok(0, $csr_b->execute());
my $r = $csr_b->fetchall_arrayref;
ok(0, $r);
ok(0, @$r);
ok(0, $r->[0]->[0] == $row_a[0]);
ok(0, $r->[0]->[1] == $row_a[1]);
ok(0, $r->[0]->[2] eq $row_a[2]);

my $csr_c;
$csr_c = $dbh->prepare("select unknown_field_name1 from ?");
ok(0, $csr_c);
ok(53, !$csr_c->execute($dir));
ok(0, $DBI::errstr =~ m/Unknown field names: unknown_field_name1/)
    or printf("Wrong error string: %s", $DBI::errstr);

$dbh->{RaiseError} = 1;
ok(0, $dbh->{RaiseError});
ok(0, $csr_c = $dbh->prepare("select unknown_field_name2 from ?"));
ok(0, !eval { $csr_c->execute(); 1 });
#print "$@\n";
ok(0, $@ =~ m/Unknown field names: unknown_field_name2/);
$dbh->{RaiseError} = 0;
ok(59, !$dbh->{RaiseError});

{
  my @warn;
  local($SIG{__WARN__}) = sub { push @warn, @_ };
  $dbh->{PrintError} = 1;
  ok(0, $dbh->{PrintError});
  ok(0, ($csr_c = $dbh->prepare("select unknown_field_name3 from ?")));
  ok(0, !$csr_c->execute());
  ok(0, "@warn" =~ m/Unknown field names: unknown_field_name3/);
  $dbh->{PrintError} = 0;
  ok(0, !$dbh->{PrintError});
}

ok(0, $csr_a = $dbh->prepare("select mode,size,name from ?"));
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

BEGIN { $tests = 68; }
