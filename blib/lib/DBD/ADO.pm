
# vim:ts=4
{
    package DBD::ADO;

    require DBI;
    require Carp;

    @EXPORT = ();
    $VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/o);

#   $Id: ADO.pm,v 1.17 2000/06/11 00:06:02 timbo Exp $
#
#   Copyright (c) 1999, Phlip & Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

    $drh = undef;       # holds driver handle once initialised
    $err = 0;           # The $DBI::err value

    sub driver{
        return $drh if $drh;
        my($class, $attr) = @_;
        $class .= "::dr";
        ($drh) = DBI::_new_drh($class, {
            'Name' => 'ADO',
            'Version' => $VERSION,
            'Attribution' => 'DBD ADO for Win32 by Phlip & Tim Bunce',
	});
        return $drh;
    }


    sub errors {
	my $Conn = shift;
	my $err_ary = [];

	my $lastError = Win32::OLE->LastError;
	push @$err_ary, ($lastError+0).": $lastError" if $lastError;

	my $Errors = $Conn->Errors();
	my $err;
	foreach $err (Win32::OLE::in($Errors)) {
	    next if $err->{Number} == 0; # Skip warnings
	    push @$err_ary, "$err->{Number}: $error->{Description}";
	}
	$Errors->Clear;
	return join "\n", @$err_ary;
    }
}


# ADO.pm lexically scoped constants
my $ado_consts;
my $VT_I4_BYREF;
my $ado_sptype;
my %ado2sql_types;
my %sql2ado_types;



{   package DBD::ADO::dr; # ====== DRIVER ======
	use Data::Dumper;
    $imp_data_size = 0;

    sub connect { my ($drh, $dsn, $user, $auth) = @_;

  	require Win32::OLE;

	unless ($ado_consts) {
	    require Win32::OLE::Const;
	    my $name = "Microsoft ActiveX Data Objects 2\\.0 Library";
	    $ado_consts = Win32::OLE::Const->Load($name)
		|| die "Unable to load Win32::OLE::Const ``$name'' ".Win32::OLE->LastError;
	    require Win32::OLE::Variant;
	    $VT_I4_BYREF = Win32::OLE::Variant::VT_I4()
			 | Win32::OLE::Variant::VT_BYREF();

	    # Required to translate between ADO and SQL type codes
	    %ado2sql_types = (
		$ado_consts->{adBigInt}  => DBI::SQL_BIGINT(),
		$ado_consts->{adBinary}	 => DBI::SQL_BINARY(),
		$ado_consts->{adBoolean} => DBI::SQL_BIT(),
		$ado_consts->{adBSTR}    => DBI::SQL_VARCHAR(),
		$ado_consts->{adChapter}    => undef,
		$ado_consts->{adChar}   => DBI::SQL_CHAR(),
		$ado_consts->{adCurrency}   => DBI::SQL_DECIMAL(),
		$ado_consts->{adDate}	=> DBI::SQL_DATE(),
		$ado_consts->{adDBDate}   => DBI::SQL_DATE(),
		$ado_consts->{adDBFileTime}   => DBI::SQL_DATE(),
		$ado_consts->{adDBTime}   => DBI::SQL_DATE(),
		$ado_consts->{adDBTimeStamp}   => DBI::SQL_TIMESTAMP(),
		$ado_consts->{adDecimal}    =>DBI::SQL_DECIMAL(),
		$ado_consts->{adDouble}	=> DBI::SQL_DOUBLE(),
		$ado_consts->{adEmpty}	=> undef,
		$ado_consts->{adError}	=> undef,
		$ado_consts->{adFileTime}   => DBI::SQL_TIME(),
		$ado_consts->{adGUID}   => undef,
		$ado_consts->{adIDispatch}   => undef,
		$ado_consts->{adInteger} => DBI::SQL_INTEGER(),
		$ado_consts->{adIUnknown}   => undef,
		$ado_consts->{adLongVarBinary}=> DBI::SQL_LONGVARBINARY(),
		$ado_consts->{adLongVarChar}=> DBI::SQL_LONGVARCHAR(),
		$ado_consts->{adLongVarWChar}=> DBI::SQL_WLONGVARCHAR(),
		$ado_consts->{adNumeric}=> DBI::SQL_DECIMAL(),
		$ado_consts->{adPropVariant}=> undef,
		$ado_consts->{adSingle}	 => DBI::SQL_REAL(),
		$ado_consts->{adSmallInt}=>DBI::SQL_SMALLINT(),
		$ado_consts->{adTinyInt} =>DBI::SQL_TINYINT(),
		$ado_consts->{adUnsignedBigInt}	 => DBI::SQL_BIGINT(),
		$ado_consts->{adUnsignedInt}	 => DBI::SQL_INTEGER(),
		$ado_consts->{adUnsignedSmallInt}=>DBI::SQL_SMALLINT(),
		$ado_consts->{adUnsignedTinyInt} => DBI::SQL_TINYINT(),
		$ado_consts->{adUserDefined} => undef,
		$ado_consts->{adVarBinary}=> DBI::SQL_VARBINARY(),
		$ado_consts->{adVarChar}=> DBI::SQL_VARCHAR(),
		$ado_consts->{adVariant}=> undef,
		$ado_consts->{adVarNumeric}=> undef,
		$ado_consts->{adVarWChar}=> DBI::SQL_WVARCHAR(),
		$ado_consts->{adWChar}=> DBI::SQL_WCHAR(),
		$ado_consts->{adVarWNumeric}=> undef
	    );

	    %sql2ado_types = (
		DBI::SQL_BINARY()   => $ado_consts->{adBinary},
		DBI::SQL_BIT()      => $ado_consts->{adBoolean},
		DBI::SQL_CHAR()     => $ado_consts->{adChar},
		DBI::SQL_DATE()     => $ado_consts->{adDBTimeStamp},
		DBI::SQL_DECIMAL()  => $ado_consts->{adNumeric},
		DBI::SQL_DOUBLE()   => $ado_consts->{adDouble},
		DBI::SQL_FLOAT()    => $ado_consts->{adSingle},
		DBI::SQL_INTEGER()  => $ado_consts->{adInteger},
		DBI::SQL_LONGVARBINARY() => $ado_consts->{adLongVarBinary},
		DBI::SQL_LONGVARCHAR() => $ado_consts->{adLongVarChar},
		DBI::SQL_NUMERIC()  => $ado_consts->{adNumeric},
		DBI::SQL_REAL()     => $ado_consts->{adSingle},
		DBI::SQL_SMALLINT() => $ado_consts->{adSmallInt},
		DBI::SQL_TIMESTAMP() => $ado_consts->{adBinary},
		DBI::SQL_TINYINT()  => $ado_consts->{adUnsignedTinyInt},
		DBI::SQL_VARBINARY() => $ado_consts->{adVarBinary},
		DBI::SQL_VARCHAR()  => $ado_consts->{adVarChar},
	    );
	}

	local $Win32::OLE::Warn = 0;
	my $conn = Win32::OLE->new('ADODB.Connection');
       
	my $lastError = Win32::OLE->LastError;
	return DBI::set_err($drh, 1,
		"Can't create 'ADODB.Connection': $lastError")
	    if $lastError;

	##  ODBC rule - Null is not the same as an empty password...
	$auth = '' if !defined $auth;
	$conn->Open ($dsn, $user, $auth);
	$lastError = DBD::ADO::errors($conn);
	return DBI::set_err( $drh, 1, 
		  "Can't connect to '$dsn': $lastError")
	    if $lastError;

	my ($this) = DBI::_new_dbh($drh, {
	    Name => $dsn,
	    User => $user,
	    ado_conn => $conn,
	});

	return $this;
    }

    sub disconnect_all { }
    sub DESTROY { }
}


# names of adSchemaProviderTypes fields
my $ado_info = [qw{
	TYPE_NAME DATA_TYPE COLUMN_SIZE LITERAL_PREFIX
	LITERAL_SUFFIX CREATE_PARAMS IS_NULLABLE CASE_SENSITIVE
	SEARCHABLE UNSIGNED_ATTRIBUTE FIXED_PREC_SCALE AUTO_UNIQUE_VALUE
	LOCAL_TYPE_NAME MINIMUM_SCALE MAXIMUM_SCALE GUID TYPELIB
	VERSION IS_LONG BEST_MATCH IS_FIXEDLENGTH
}];
# XXX check IS_NULLABLE => NULLABLE (only difference with DBI/ISO field names)

# Information returned from the provider about the schema.  The column names
# are different then the DBI spec.
my $ado_schematables = [
	qw{ TABLE_CATALOG TABLE_SCHEMA TABLE_NAME TABLE_TYPE DESCRIPTION TABLE_GUID
		TABLE_PROPID DATE_CREATED DATE_MODIFIED
	} ];



{   package DBD::ADO::db; # ====== DATABASE ======
    $imp_data_size = 0;

    use strict;

    sub prepare {
	my($dbh, $statement, $attribs) = @_;
	my ($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'   => $statement,
	});
	$sth->{ado_conn} = $dbh->{ado_conn};
	$outer;
    }

    # Get information from the current provider.
    sub GetTypeInfo {
	my($dbh, $attribs) = @_;
	my @tp;
	my $oRec = $dbh->{ado_conn}->OpenSchema($ado_consts->{adSchemaProviderTypes});

	while(! $oRec->{EOF}) {
	    #print "attrib $attribs ",
	    #"LongVarChar ", DBI::SQL_LONGVARCHAR,
	    #"adLongVarChar ", $ado_consts->{adLongVarChar},
	    #"Data Type ", $oRec->{DATA_TYPE}->Value,
	    #"\n";
	    next unless ($attribs == DBI::SQL_ALL_TYPES() or
		    $sql2ado_types{$attribs} == $oRec->{DATA_TYPE}->Value);
	    my ($d, @out);
	    foreach $d (@$ado_info) {
		push(@out, $oRec->{$d}->Value || '' );
	    }
	    push( @tp, \@out );
	}
	continue {
	    $oRec->MoveNext unless $oRec->{EOF};
	}

	my $sponge = DBI->connect("dbi:Sponge:","","",{ RaiseError => 1 });
	my $sth = $sponge->prepare("adSchemaProviderTypes", {
		rows=> [ @tp ], NAME=> $ado_info,
	});
	$sth;
    }


	sub table_info {
	my($dbh, $attribs) = @_;
	my @tp;
		my $oRec = $dbh->{ado_conn}->OpenSchema($ado_consts->{adSchemaTables});

		while(! $oRec->{EOF}) {
			my @out;
			for my $d (@$ado_schematables) {
				push(@out, $oRec->{$d}->Value || '' );
			}
			push( @tp, \@out );
		} continue {
			$oRec->MoveNext unless $oRec->{EOF};
		}

		my $statement = "adSchemaTables";
		my $sponge = DBI->connect("dbi:Sponge:","","",{ RaiseError => 1 });
		my $sth = $sponge->prepare($statement,
			{ rows=> [ @tp ], NAME=> $ado_schematables, });
	$sth;
	}


    sub type_info_all {
	my ($dbh) = @_;
	my $names = {
          TYPE_NAME		=> 0,
          DATA_TYPE		=> 1,
          COLUMN_SIZE		=> 2,
          LITERAL_PREFIX	=> 3,
          LITERAL_SUFFIX	=> 4,
          CREATE_PARAMS		=> 5,
          NULLABLE		=> 6,
          CASE_SENSITIVE	=> 7,
          SEARCHABLE		=> 8,
          UNSIGNED_ATTRIBUTE	=> 9,
          FIXED_PREC_SCALE	=>10,
          AUTO_UNIQUE_VALUE	=>11,
          LOCAL_TYPE_NAME	=>12,
          MINIMUM_SCALE		=>13,
          MAXIMUM_SCALE		=>14,
        };
	# Based on the values from the current provider.
	my @myti;
	my $sth = $dbh->func( DBI::SQL_ALL_TYPES, 'GetTypeInfo' );
	while(my $row = $sth->fetchrow_hashref) {
		my @tyinfo;
		# Only add items from the above names list.  When
		# this list explans, the code 'should' still work.
		for my $n (keys %{$names}){
			$tyinfo[ $names->{$n} ] = $row->{$n} || '';
		}
		# Convert the ADO type to SQL type.
		$tyinfo[$names->{DATA_TYPE}] = $ado2sql_types{$tyinfo[$names->{DATA_TYPE}]} || $tyinfo[$names->{DATA_TYPE}];
		push( @myti, \@tyinfo );
	}
	$sth->finish;
	my $ti = [ $names, @myti ];

	return $ti;
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
            Carp::croak("Can't disable AutoCommit");
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
	my $sql  = $sth->{Statement};

	my $rows = Win32::OLE::Variant->new($VT_I4_BYREF, 0);
	my $rs = $conn->Execute($sql, $rows, $ado_consts->{adCmdText});

	local $Win32::OLE::Warn = 0;
	my $lastError = DBD::ADO::errors($conn);
	return DBI::set_err( $sth, 1, 
		  "Can't execute statement '$sql': $lastError")
	    if $lastError;

	$sth->{ado_rs} = $rs;
	$sth->{ado_fields} = my $ado_fields = [ Win32::OLE::in($rs->Fields) ];
	my $NUM_OF_FIELDS = @$ado_fields;

	$sth->trace_msg("$conn->Execute=$rs. NUM_OF_FIELDS=$NUM_OF_FIELDS, rows=$rows\n");

	if ($NUM_OF_FIELDS == 0) {	# assume non-select statement
	    return $rows;
	}

        $sth->STORE(Active => 1);
	$sth->STORE(NUM_OF_FIELDS => $NUM_OF_FIELDS);
	$sth->{NAME} = [ map { $_->Name } @$ado_fields ];

	# We need to return a true value for a successful select
	# -1 means total row count unavailable
	return -1;
    }


    sub fetch {			# XXX needs error checking added
	my ($sth) = @_;
	my $rs = $sth->{ado_rs};

	if ($rs->EOF) {
	    $sth->finish;
	    $sth->{ado_rs} = undef;
	    return undef;
	}

	my $ado_fields = $sth->{ado_fields};

	my $row = [ map { $_->Value } @$ado_fields ];

	$rs->MoveNext;	# XXX need to check for errors and record for next itteration

	return $sth->_set_fbav($row);
    }
    *fetchrow_arrayref = \&fetch;


    sub finish {
        my ($sth) = @_;
        my $rs = $sth->{ado_rs};
	$rs->Close () if $rs and $rs->State & $ado_consts->{adStateOpen};
        $sth->STORE(Active => 0);
	#  undef $sth->{ado_rs};
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


    sub ColAttributes {         # maps to SQLColAttributes
	my ($sth, $colno, $desctype) = @_;
	print "before ColAttributes $colno $desctype\n";
	# my $tmp = _ColAttributes($sth, $colno, $desctype);
	print "After ColAttributes\n";
	# $tmp;
    }


    sub DESTROY { }
}

1;
__END__

=head1 NAME

DBD::ADO - A DBI driver for Microsoft ADO (Active Data Objects)

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect("dbi:ADO:dsn", $user, $passwd);

  # See the DBI module documentation for full details

=head1 DESCRIPTION

To be written

=head1 ADO

It is strongly recommended that you use the latest version of ADO
(2.1 at the time this was written). You can download it from:

  http://www.microsoft.com/Data/download.htm

=head1 AUTHORS

Phlip and Tim Bunce. With many thanks to Jan Dubois, Jochen Wiedmann
and Thomas Lowery for additions, debuggery and general help.

=head1 SEE ALSO

ADO Reference book:  ADO 2.0 Programmer's Reference, David Sussman and
Alex Homer, Wrox, ISBN 1-861001-83-5. If there's anything better please
let me know.

http://www.able-consulting.com/tech.htm

=cut
