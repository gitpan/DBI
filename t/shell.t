#!../../perl -w

$|=1;

print "1..$tests\n";

sub ok ($$) {
    my($n, $ok) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
		if $n and $n != $t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
}

use DBI::Shell;
ok(0,1);

my $sh = DBI::Shell::Std->new(qw(dbi:ExampleP:));
ok(0,1);

$sh->load_plugins;
ok(0,1);



BEGIN { $tests = 3 }

