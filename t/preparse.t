#!perl -w

use DBI qw(:preparse_flags);

$|=1;
$^W=1;

*pp = \&DBI::preparse;
sub ok($;$);

print "1..$tests\n";

# ---------------------------------------------------------------------

#  DBIpp_cm_cs DBIpp_cm_hs DBIpp_cm_dd DBIpp_cm_br
#  DBIpp_ph_qm DBIpp_ph_cn DBIpp_ph_cs DBIpp_ph_sp

#  pp h  input		return		accept		expected
ok pp(0, "",		0,		0),		"";
ok pp(0, "foo\nbar",	0,		0),		"foo\nbar";

# Comments:
#ok pp(0, "a#b\nc",	DBIpp_cm_cs,	DBIpp_cm_hs),	"a/*b*/\nc";
#ok pp(0, "a#b\nc",	DBIpp_cm_dd,	DBIpp_cm_hs),	"a -- b\nc"; # add space if none
#ok pp(0, "a/*b*/c",	DBIpp_cm_hs,	DBIpp_cm_cs),	"a#b\nc";

# Placeholders:

# Placeholders inside comments (should be ignored where comments style is accepted):

# Placeholders inside single and double quotes (should be ignored):

# Comments inside single and double quotes (should be ignored):

# Single and double quoted strings starting inside comments (should be ignored):

# Check error conditions are trapped:


# ---------------------------------------------------------------------

BEGIN { $tests = 2; }

sub ok ($;$) {
    my ($result, $expected) = @_;
    my $ok;
    if (@_ == 1) {
	$ok = $result;
    } elsif (!defined $expected) {
	$ok = !defined $result;
    } elsif (!defined $result) {
	$ok = 0;
    } else {
	$ok = $result eq $expected;
    }
    ++$t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    warn "# failed test $t at line ".(caller)[2]." expected '$expected', got '$result'\n" unless $ok;
    return $ok;
}
	
