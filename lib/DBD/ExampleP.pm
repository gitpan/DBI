{
    package DBD::ExampleP;

    use DBI qw(:sql_types);

    @EXPORT = qw(); # Do NOT @EXPORT anything.

#   $Id: ExampleP.pm,v 10.3 1999/01/06 13:07:22 timbo Exp $
#
#   Copyright (c) 1994,1997,1998 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

    @statnames = qw(dev ino mode nlink
	uid gid rdev size
	atime mtime ctime
	blksize blocks name);
    @statnames{@statnames} = (0 .. @statnames-1);

    @stattypes = (SQL_INTEGER, SQL_INTEGER, SQL_INTEGER, SQL_INTEGER,
	SQL_INTEGER, SQL_INTEGER, SQL_INTEGER, SQL_INTEGER,
	SQL_INTEGER, SQL_INTEGER, SQL_INTEGER,
	SQL_INTEGER, SQL_INTEGER, SQL_VARCHAR);
    @stattypes{@statnames} = @stattypes;

    $drh = undef;	# holds driver handle once initialised
    $err = 0;		# The $DBI::err value
    $gensym = "SYM000"; # used by st::execute() for filehandles

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, {
	    'Name' => 'ExampleP',
	    'Version' => '$Revision: 10.3 $',
	    'Attribution' => 'DBD Example Perl stub by Tim Bunce',
	    }, ['example implementors private data']);
	$drh;
    }

    1;
}


{   package DBD::ExampleP::dr; # ====== DRIVER ======
    $imp_data_size = 0;
    use strict;

    sub my_handler {
	my($self, $type, @args) = @_;
	return 0 unless $type eq 'ERROR';
	${$self->{Err}}    = $args[0];
	${$self->{Errstr}} = $args[1];
	1;	# handled
    }

    sub connect { # normally overridden, but a handy default
        my($drh, $dbname, $user, $auth)= @_;
        my($this) = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'User' => $user,
	    'Handlers' => [ \&my_handler ],	# deprecated, don't do this
	    });
		$this->STORE(Active => 1);
        $this;
    }

    sub data_sources {
	return ("dbi:ExampleP:dir=.");	# possibly usefully meaningless
    }

    sub disconnect_all {
	# we don't need to tidy up anything
    }
    sub DESTROY { undef }
}


{   package DBD::ExampleP::db; # ====== DATABASE ======
    $imp_data_size = 0;
    use strict;

    sub prepare {
	my($dbh, $statement)= @_;

	my($fields, $param)
		= $statement =~ m/^select\s+(.*?)\s+from\s+(\S*)/i;
	unless (defined $fields and defined $param) {
	    $dbh->event("ERROR", 1, "Syntax error in select statement");
	    return undef;
	}

	my @fields = ($fields eq '*')
			? keys %DBD::ExampleP::statnames
			: split(/\s*,\s*/, $fields);

	my @bad = map {
	    defined $DBD::ExampleP::statnames{$_} ? () : $_
	} @fields;
	if (@bad) {
	    $dbh->event("ERROR", 1, "Unknown field names: @bad");
	    return undef;
	}

	my ($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'     => $statement,
	}, ['example implementors private data']);

	$sth->{'dbd_param'}->[1] = $param if $param !~ /\?/;

	$outer->STORE('NAME' => \@fields);
	$outer->STORE('NULLABLE' => [ (0) x @fields ]);
	$outer->STORE('NUM_OF_FIELDS' => scalar(@fields));
	$outer->STORE('NUM_OF_PARAMS' => ($param !~ /\?/) ? 0 : 1);

	$outer;
    }


    sub type_info_all {
	my ($dbh) = @_;
	my $ti = [
	    {	TYPE_NAME	=> 0,
		DATA_TYPE	=> 1,
		PRECISION	=> 2,
		LITERAL_PREFIX	=> 3,
		LITERAL_SUFFIX	=> 4,
		CREATE_PARAMS	=> 5,
		NULLABLE	=> 6,
		CASE_SENSITIVE	=> 7,
		SEARCHABLE	=> 8,
		UNSIGNED_ATTRIBUTE=> 9,
		MONEY		=> 10,
		AUTO_INCREMENT	=> 11,
		LOCAL_TYPE_NAME	=> 12,
		MINIMUM_SCALE	=> 13,
		MAXIMUM_SCALE	=> 14,
	    },
	    [ 'VARCHAR', DBI::SQL_VARCHAR, undef, "'","'", undef, 0, 1, 1, 0, 0,0,undef,0,0 ],
	    [ 'INTEGER', DBI::SQL_INTEGER, undef, "","",   undef, 0, 0, 1, 0, 0,0,undef,0,0 ],
	];
	return $ti;
    }


    sub disconnect {
	shift->STORE(Active => 0);
	return 1;
    }

    sub FETCH {
	my ($dbh, $attrib) = @_;
	# In reality this would interrogate the database engine to
	# either return dynamic values that cannot be precomputed
	# or fetch and cache attribute values too expensive to prefetch.
	return 1 if $attrib eq 'AutoCommit';
	# else pass up to DBI to handle
	return $dbh->SUPER::FETCH($attrib);
    }

    sub STORE {
	my ($dbh, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	if ($attrib eq 'AutoCommit') {
	    return 1 if $value;	# is already set
	    croak("Can't disable AutoCommit");
	}
	return $dbh->SUPER::STORE($attrib, $value);
    }
    sub DESTROY {
	my $dbh = shift;
	$dbh->disconnect if $dbh->FETCH('Active');
	undef
    }
}


{   package DBD::ExampleP::st; # ====== STATEMENT ======
    $imp_data_size = 0;
    use strict; no strict 'refs'; # cause problems with filehandles

    sub bind_param {
	my($sth, $param, $value, $attribs) = @_;
	$sth->{'dbd_param'}->[$param] = $value;
    }
	
    sub execute {
	my($sth, @dir) = @_;
	my $dir;
	if (@dir) {
	    $dir = $dir[0];
	} else {
	    $dir = $sth->{'dbd_param'}->[1];
	    unless (defined $dir) {
		$sth->event("ERROR", 2, "No bind parameter supplied");
		return undef;
	    }
	}
	$sth->finish;
	$sth->{dbd_datahandle} = "DBD::ExampleP::".++$DBD::ExampleP::gensym;
	opendir($sth->{dbd_datahandle}, $dir)
		or ($sth->event("ERROR", 2, "opendir($dir): $!"), return undef);
	$sth->{dbd_dir} = $dir;
	1;
    }

    sub fetch {
	my $sth = shift;
	my $f = readdir($sth->{dbd_datahandle});
	unless($f){
	    $sth->finish;     # no more data so finish
	    return;
	}
	my %s; # fancy a slice of a hash?
	# put in all the data fields
	@s{@DBD::ExampleP::statnames} = (stat("$sth->{'dbd_dir'}/$f"), $f);
	# return just what fields the query asks for
	my @new = @s{ @{$sth->{NAME}} };

	#my $row = $sth->_get_fbav;
	#@$row =  @new;
	#$row->[0] = $new[0]; $row->[1] = $new[1]; $row->[2] = $new[2];
	return $sth->_set_fbav(\@new);
    }
    *fetchrow_arrayref = \&fetch;

    sub finish {
	my $sth = shift;
	return undef unless $sth->{dbd_datahandle};
	closedir($sth->{dbd_datahandle});
	$sth->{dbd_datahandle} = undef;
	return 1;
    }

    sub FETCH {
	my ($sth, $attrib) = @_;
	# In reality this would interrogate the database engine to
	# either return dynamic values that cannot be precomputed
	# or fetch and cache attribute values too expensive to prefetch.
	if ($attrib eq 'TYPE'){
	    my @t = @DBD::ExampleP::stattypes{@{$sth->{NAME}}};
	    return \@t;
	}
	# else pass up to DBI to handle
	return $sth->SUPER::FETCH($attrib);
    }

    sub STORE {
	my ($sth, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	return $sth->{$attrib}=$value
	    if $attrib eq 'NAME' or $attrib eq 'NULLABLE';
	return $sth->SUPER::STORE($attrib, $value);
    }

    sub DESTROY { undef }
}

1;
