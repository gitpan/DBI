
# THIS IS *VERY* UNTESTED - THROWN TOGETHER IN A FEW MINUTES

{
    package DBD::ADO;

    require DBI;
    require Carp;

    @EXPORT = qw();

#   $Id: ADO.pm,v 1.2 1999/01/04 15:35:40 timbo Exp $
#
#   Copyright (c) 1998, Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

    $drh = undef;	# holds driver handle once initialised
    $err = 0;		# The $DBI::err value

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, {
	    'Name' => 'ADO',
	    'Version' => '$Revision: 1.2 $',
	    'Attribution' => 'DBD ADO for Win32 by Tim Bunce',
	    });
	$drh;
    }

    1;
}


{   package DBD::ADO::dr; # ====== DRIVER ======
    $imp_data_size = 0;

    sub connect { # normally overridden, but a handy default
	my($drh, $dsn, $user, $auth)= @_;
	my $dsn_auth = $dsn;
	$dsn_auth .= ";UID=$user" if defined $user;
	$dsn_auth .= ";PWD=$auth" if defined $auth;
	require Win32::OLE;
	my $conn = Win32::OLE->new("ADODB.Connection");
	$conn->Open($dsn_auth);	# XXX check for errors!
	my($this) = DBI::_new_dbh($drh, {
	    'Name' => $dsn,
	    'User' => $user,
	    ado_conn => $conn,
	    });
	$this;
    }

    sub disconnect_all { }
    sub DESTROY { }
}


{   package DBD::ADO::db; # ====== DATABASE ======
    $imp_data_size = 0;
    use strict;

    sub prepare {
	my($dbh, $statement, $attribs) = @_;

	my ($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'   => $statement,
	});
	$outer;
    }

    sub FETCH {
        my ($dbh, $attrib) = @_;
        # In reality this would interrogate the database engine to
        # either return dynamic values that cannot be precomputed
        # or fetch and cache attribute values too expensive to prefetch.
        return 1 if $attrib eq 'AutoCommit';
        # else pass up to DBI to handle
        return $dbh->DBD::_::db::FETCH($attrib);
    }

    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        # would normally validate and only store known attributes
        # else pass up to DBI to handle
        if ($attrib eq 'AutoCommit') {
            return 1 if $value; # is already set
            croak("Can't disable AutoCommit");
        }
        return $dbh->DBD::_::db::STORE($attrib, $value);
    }

    sub DESTROY { }

}


{   package DBD::ADO::st; # ====== STATEMENT ======
    $imp_data_size = 0;
    use strict;

    sub execute {
	my ($sth) = @_;
	my $conn = $sth->{ado_conn};
	my $sql = $sth->{Statemement};
	my $rs = $conn->Execute($sql);
	$sth->{ado_rs} = $rs;
	$rs;
    }

    sub fetch {
	my ($sth) = @_;
	my $conn = $sth->{ado_conn};
	if ($conn->EOF) {
	    $sth->finish;
	    $sth->{ado_rs} = undef;
	    return undef;
	}
	my $row = $conn->Fields();
	$conn->MoveNext;
	return $sth->_set_fbav($row);
    }
    *fetchrow_arrayref = \&fetch;

    sub finish {
	shift->STORE(Active => 0);
    }

    sub FETCH {
	my ($sth, $attrib) = @_;
	# would normally validate and only fetch known attributes
	# else pass up to DBI to handle
	return $sth->DBD::_::dr::FETCH($attrib);
    }

    sub STORE {
	my ($sth, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	return $sth->DBD::_::dr::STORE($attrib, $value);
    }

    sub DESTROY { }
}

1;
