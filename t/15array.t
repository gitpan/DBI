use strict;
use Test;

BEGIN { plan tests => 24 }

use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;

use DBI;

my $dbh = DBI->connect("dbi:Sponge:dummy", '', '', { RaiseError=>1, AutoCommit=>1 });
ok($dbh);

my $rows = [ ];
my $tuple_status = [];
my $dumped;

#$dbh->trace(2);

my $sth = $dbh->prepare("insert", {
	rows => $rows,		# where to 'insert' (push) the rows
	NUM_OF_PARAMS => 4,
	# DBD::Sponge hook to make certain data trigger an error for that row
	execute_hook => sub { return $_[0]->set_err(1,"errmsg") if grep { $_ eq "B" } @_; 1 },
});
ok($sth);

ok( @$rows, 0 );
ok( $sth->execute_array( { ArrayTupleStatus => $tuple_status },
	[ 1, 2, 3 ],	# array of integers
	42,		# scalar 42 treated as array of 42's
	undef,		# scalar undef treated as array of undef's
	[ qw(A B C) ],	# array of strings
    ),
    undef
);

ok( @$rows, 2 );
ok( @$tuple_status, 3 );

$dumped = Dumper($rows);
ok( $dumped, "[[1,42,undef,'A'],[3,42,undef,'C']]");	# missing row containing B

$dumped = Dumper($tuple_status);
ok( $dumped, "[1,[1,'errmsg'],1]");			# row containing B has error


# --- change one param and re-execute

@$rows = ();
ok( $sth->bind_param_array(4, [ qw(a b c) ]) );
ok( $sth->execute_array({ ArrayTupleStatus => $tuple_status }) );

ok( @$rows, 3 );
ok( @$tuple_status, 3 );

$dumped = Dumper($rows);
ok( $dumped, "[[1,42,undef,'a'],[2,42,undef,'b'],[3,42,undef,'c']]");

$dumped = Dumper($tuple_status);
ok( $dumped, "[1,1,1]");


# --- error detection tests ---

$sth->{RaiseError} = 0;
$sth->{PrintError} = 0;
#$sth->trace(2);

ok( $sth->execute_array( { ArrayTupleStatus => $tuple_status }, [1],[2]), undef );
ok( $sth->errstr, '2 bind values supplied but 4 expected' );

ok( $sth->execute_array( { ArrayTupleStatus => { } }, [ 1, 2, 3 ]), undef );
ok( $sth->errstr, 'ArrayTupleStatus attribute must be an arrayref' );

ok( $sth->execute_array( { ArrayTupleStatus => $tuple_status }, 1,{},3,4), undef );
ok( $sth->errstr, 'Value for parameter 2 must be a scalar or an arrayref, not a HASH' );

ok( $sth->execute_array( { ArrayTupleStatus => $tuple_status }, 1,[1],[2,2],3), undef );
ok( $sth->errstr, 'Arrayref for parameter 3 has 2 elements but parameter 2 has 1' );

ok( $sth->bind_param_array(":foo", [ qw(a b c) ]), undef );
ok( $sth->errstr, "Can't use named placeholders for non-driver supported bind_param_array");

exit 0;
