#!perl -w

$|=1;
$^W=1;

my $calls = 0;


# =================================================
# Example code for sub classing the DBI.
#
# Note that the extra ::db and ::st classes must be set up
# as sub classes of the corresponding DBI classes.
#
# This whole mechanism is new and experimental - it may change!

package MyDBI;
@ISA = qw(DBI);

package MyDBI::dr;
@ISA = qw(DBI::dr);

sub connect {
    my ($drh, $dsn, $user, $pass, $attr) = @_;
    my $dbh = $drh->SUPER::connect($dsn, $user, $pass, $attr);
    delete $attr->{CompatMode};	# to test clone
    return $dbh;
}

package MyDBI::db;
@ISA = qw(DBI::db);

sub prepare {
    my($dbh, @args) = @_;
    ++$calls;
    my $sth = $dbh->SUPER::prepare(@args);
    return $sth;
}


package MyDBI::st;
@ISA = qw(DBI::st);

sub fetch {
    my($sth, @args) = @_;
    ++$calls;
    my $row = $sth->SUPER::fetch(@args);
    if ($row) {
	# modify fetched data as an example
	$row->[1] = lc($row->[1]);

	# also demonstrate calling set_err()
	return $sth->set_err(1,"Don't be so negative",undef,"fetch")
		if $row->[0] < 0;
	# ... and providing alternate results
	# (although typically would trap and hide and error from SUPER::fetch)
	return $sth->set_err(2,"Don't exagerate",undef, undef, [ 42,"zz",0 ])
		if $row->[0] > 42;
    }
    return $row;
}


# =================================================
package main;

print "1..$tests\n";

sub ok ($$$) {
    my($n, $got, $want) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
	if $n and $n != $t;
    my $line = (caller)[2];
    return print "ok $t at $line\n"
	if(	( defined($got) && defined($want) && $got eq $want)
	||	(!defined($got) && !defined($want)) );
    warn "Test $n: wanted '$want', got '$got'\n";
    print "not ok $t at $line\n";
}


# =================================================
package main;

use DBI;

#DBI->trace(2);
$dbh = MyDBI->connect("dbi:Sponge:foo","","", {
	PrintError => 0,
	RaiseError => 1,
	CompatMode => 1, # just for clone test
});
ok(0, ref $dbh, 'MyDBI::db');
ok(0, $dbh->{CompatMode}, 1);

#$dbh->trace(5);
$sth = $dbh->prepare("foo",
    # data for DBD::Sponge to return via fetch
    { rows => [
	[ 40, "AAA", 9 ],
	[ 41, "BB",  8 ],
	[ -1, "C",   7 ],
	[ 49, "DD",  6 ]
	],
    }
);

ok(0, $calls, 1);
ok(0, ref $sth, 'MyDBI::st');

my $row = $sth->fetch;
ok(0, $calls, 2);
ok(0, $row->[1], "aaa");

$row = $sth->fetch;
ok(0, $calls, 3);
ok(0, $row->[1], "bb");

ok(0, $DBI::err, undef);
$row = eval { $sth->fetch };
ok(0, !defined $row, 1);
ok(0, substr($@,0,50), "DBD::Sponge::st fetch failed: Don't be so negative");

#$sth->trace(5);
#$sth->{PrintError} = 1;
$sth->{RaiseError} = 0;
$row = eval { $sth->fetch };
ok(0, ref $row, 'ARRAY');
ok(0, $row->[0], 42);
ok(0, $DBI::err, 2);
ok(0, $DBI::errstr =~ /Don't exagerate/, 1);
ok(0, $@ =~ /Don't be so negative/, $@);


print "clone A\n";
my $dbh2 = $dbh->clone;
ok(0, $dbh2 != $dbh, 1);
ok(0, ref $dbh2, 'MyDBI::db');
ok(0, $dbh2->{CompatMode}, 1);

print "clone B\n";
my $dbh3 = $dbh->clone;
ok(0, $dbh3 != $dbh, 1);
ok(0, $dbh3 != $dbh2, 1);
ok(0, ref $dbh3, 'MyDBI::db');
ok(0, $dbh3->{CompatMode}, 1);


BEGIN { $tests = 23 }
