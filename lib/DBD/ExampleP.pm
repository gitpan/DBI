{
    package DBD::ExampleP;

    require DBI;

    @EXPORT = qw(); # Do NOT @EXPORT anything.

#   $Id: ExampleP.pm,v 1.2 1996/01/29 19:34:36 timbo Exp $
#
#   Copyright (c) 1994, Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

    @statnames = qw(dev ino mode nlink uid gid
	rdev size atime mtime ctime blksize blocks name);
    @statnames{@statnames} = (0 .. @statnames-1);
    @stattypes = qw(1 1 1 1 1 1 1 1 3 3 3 1 1 2);
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
	    'Version' => '$Revision: 1.2 $',
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
	    'Handlers' => [ \&my_handler ],
	    });
        $this;
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
	my($fields, $param) = $statement =~ m/^select ([\w,\s]+) from (.*)/i;
	my(@fields) = split(/\s*,\s*/, $fields);

	my(@bad) = map($DBD::ExampleP::statnames{$_} ? () : $_, @fields);
	if (@bad) {
	    $dbh->event("ERROR", "Unknown field names: @bad");
	    return undef;
	}

	my($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'     => $statement,
	    'fields'        => \@fields,
	    }, ['example implementors private data']);

	$outer->{NUM_OF_FIELDS} = @fields;
	$outer->{NUM_OF_PARAMS} = 1;

	$outer;
    }

    sub DESTROY { undef }
}


{   package DBD::ExampleP::st; # ====== STATEMENT ======
    $imp_data_size = 0;
    use strict; no strict 'refs'; # cause problems with filehandles

    sub bind_param {
	my($sth, $param, $value, $attribs) = @_;
	$sth->{'param'}->[$param] = $value;
    }
	
    sub execute {
	my($sth, @dir) = @_;
	my $dir;
	if (@dir) {
	    $dir = $dir[0];
	} else {
	    $dir = $sth->{'param'}->[1] || die "No bind_param";
	}
	$sth->finish;
	$sth->{'datahandle'} = "DBD::ExampleP::".++$DBD::ExampleP::gensym;
	opendir($sth->{'datahandle'}, $dir)
		or ($sth->event("ERROR", "opendir($dir): $!"), return undef);
	$sth->{'dir'} = $dir;
	1;
    }

    sub fetchrow {
	my($sth) = @_;
	my $f = readdir($sth->{'datahandle'});
	unless($f){
	    $sth->finish;     # no more data so finish
	    return ();
	}
	my(%s); # fancy a slice of a hash?
	# put in all the data fields
	@s{@DBD::ExampleP::statnames} = (stat("$sth->{'dir'}/$f"), $f);
	# return just what fields the query asks for
	@s{ @{$sth->{'fields'}} };
    }

    sub finish {
	my($sth) = @_;
	return undef unless $sth->{'datahandle'};
	closedir($sth->{'datahandle'});
	$sth->{'datahandle'} = undef;
    }

    sub FETCH {
	my ($sth, $attrib) = @_;
	# In reality this would interrogate the database engine to
	# either return dynamic values that cannot be precomputed
	# or fetch and cache attribute values too expensive to prefetch.
	if ($attrib eq 'DATA_TYPE'){
	    my(@t) = @DBD::ExampleP::stattypes{@{$sth->{'fields'}}};
	    return \@t;
	}
	# else pass up to DBI to handle
	return $sth->DBD::_::dr::FETCH($attrib);
    }

    sub STORE {
	my ($sth, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	return $sth->DBD::_::dr::STORE($attrib, $value);
    }

    sub DESTROY { undef }
}

1;
