#   -*- perl -*-
#
#
#   DBD::Proxy - DBI Proxy driver
#
# 
#   Copyright (c) 1997,1998  Jochen Wiedmann
#
#   The DBD::Proxy module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself. In particular permission
#   is granted to Tim Bunce for distributing this as a part of the DBI.
#
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: joe@ispsoft.de
#           Phone: +49 7123 14881
# 

use strict;

require DBI;
DBI->require_version(0.9301);

require IO::Socket;
require RPC::pClient;



package DBD::Proxy;

use vars qw($VERSION $err $errstr $drh);


$VERSION = "0.1004";

$err = 0;		# holds error code   for DBI::err
$errstr = "";		# holds error string for DBI::errstr
$drh = undef;		# holds driver handle once initialised


sub driver ($$) {
    if (!$drh) {
	my($class, $attr) = @_;

	$class .= "::dr";

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Proxy',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::Proxy::err,
	    'Errstr' => \$DBD::Proxy::errstr,
	    'Attribution' => 'DBD::Proxy by Jochen Wiedmann',
	    });
    }
    $drh;
}


package DBD::Proxy::dr; # ====== DRIVER ======

$DBD::Proxy::dr::imp_data_size = 0;

sub connect ($$;$$) {
    my($drh, $dsn, $user, $auth)= @_;
    my($dsnOrig) = $dsn;

    my %attr;
    my ($var, $val);
    while (length($dsn)) {
	if ($dsn =~ /^dsn=(.*)/) {
	    $attr{'dsn'} = $1;
	    last;
	}
	if ($dsn =~ /^(.*?);(.*)/) {
	    $var = $1;
	    $dsn = $2;
	} else {
	    $var = $dsn;
	    $dsn = '';
	}
	if ($var =~ /^(.*?)=(.*)/) {
	    $var = $1;
	    $val = $2;
	    $attr{$var} = $val;
	}
    }

    my $err = '';
    if (!defined($attr{'hostname'})) { $err .= " Missing hostname."; }
    if (!defined($attr{'port'}))     { $err .= " Missing port."; }
    if (!defined($attr{'dsn'}))      { $err .= " Missing remote dsn."; }

    # Create a cipher object, if requested
    my $cipherRef = undef;
    if ($attr{'cipher'}) {
	$cipherRef = eval { $attr{'cipher'}->new(pack('H*',
							$attr{'key'})) };
	if ($@) { $err .= " Cannot create cipher object: $@."; }
    }
    my $userCipherRef = undef;
    if ($attr{'userkey'}) {
	my $cipher = $attr{'usercipher'} || $attr{'cipher'};
	$userCipherRef = eval { $cipher->new(pack('H*', $attr{'userkey'})) };
	if ($@) { $err .= " Cannot create usercipher object: $@."; }
    }

    if ($err) { DBI::set_err($drh, 1, $err); return undef; }

    # Create an IO::Socket object
    my $sock;
    $sock = IO::Socket::INET->new('Proto' => 'tcp',
				  'PeerAddr' => $attr{'hostname'},
				  'PeerPort' => $attr{'port'});
    if (!$sock) {
	DBI::set_err($drh, 1, "Cannot connect: $!");
	return undef;
    }

    # Need to avoid "Can't store LVALUE items" bug in Storable
    # when refering to non-existant hash entries.
    my $client = RPC::pClient->new(
	'sock' => $sock,
	'application' => $attr{dsn},
	'user' => $attr{user} || '',
	'password' => $attr{auth} || '',
	'version' => $DBD::Proxy::VERSION,
	'cipher' => $cipherRef,
	'debug' => $attr{debug}||0
    );

    if (!ref($client)) {
        DBI::set_err($drh, 1, "Cannot log in to DBI::ProxyServer: $client");
	return undef;
    }

    # Switch to user specific encryption mode, if desired
    if ($userCipherRef) {
	$client->Encrypt($userCipherRef);
    }

    my($status, $dbh) = $client->CallInt('connect', $attr{'dsn'},
					 $user, $auth);
    if (!$status) {
        DBI::set_err($drh, 1, "Error while connecting to remote DSN: $dbh");
	return undef;
    }

    # create a 'blank' dbh
    my $this = DBI::_new_dbh($drh, { 'Name' => $dsnOrig,
				     'proxy_dbh' => $dbh,
				     'proxy_client' => $client});

    foreach $var (keys %attr) {
	if ($var =~ /proxy_/) {
	    $this->{$var} = $attr{$var};
	}
    }

    $this;
}


sub disconnect_all { }

sub DESTROY { undef }


package DBD::Proxy::db; # ====== DATABASE ======

$DBD::Proxy::db::imp_data_size = 0;

use vars qw(%ATTR);

%ATTR = (
    'Warn' => 'local',
    'Active' => 'local',
    'Kids' => 'local',
    'CachedKids' => 'local',
    'PrintError' => 'local',
    'RaiseError' => 'local',
);

sub commit ($) {
    my($dbh) = @_;
    my($status, $result) =
	$dbh->{'proxy_client'}->CallInt('method', $dbh->{'proxy_dbh'},
					'commit');
    if (!$status) {
        DBI::set_err($dbh, 1, $result);
	$result = 0;
    }
    $result;
}

sub rollback ($) {
    my($dbh) = @_;
    my($status, $result) =
	$dbh->{'proxy_client'}->CallInt('method', $dbh->{'proxy_dbh'},
					'rollback');
    if (!$status) {
        DBI::set_err($dbh, 1, $result);
	$result = 0;
    }
    $result;
}

sub disconnect ($) {
    my($dbh) = @_;
    delete $dbh->{'proxy_dbh'};
    delete $dbh->{'proxy_client'};
}


sub STORE ($$$) {
    my($dbh, $attr, $val) = @_;
    my $type = $ATTR{$attr} || 'remote';

    if ($attr =~ /^proxy_/) {
	$dbh->{$attr} = $val;
	return 1;
    }

    if ($type eq 'remote') {
	my($status, $result) =
	    $dbh->{'proxy_client'}->CallInt('method', $dbh->{'proxy_dbh'},
					    'STORE', $attr, $val);
	if (!$status) {
	    DBI::set_err($dbh, 1, $result);
	    return 0;
	}
	return $result;
    }
    return $dbh->DBD::_::db::STORE($attr, $val);
}

sub FETCH ($$) {
    my($dbh, $attr) = @_;
    my $type = $ATTR{$attr} || 'remote';

    if ($attr =~ /^proxy_/) {
	return $dbh->{$attr};
    }

    if ($type eq 'remote') {
	my($status, $result) =
	    $dbh->{'proxy_client'}->CallInt('method', $dbh->{'proxy_dbh'},
					    'FETCH', $attr);
	if (!$status) {
	    DBI::set_err($dbh, 1, $result);
	    return undef;
	}
	$result;
    } else {
	$dbh->DBD::_::db::FETCH($attr);
    }
}

sub prepare ($$;$) {
    my($dbh, $stmt, $attr) = @_;

    # We *could* send the statement over the net immediately, but the
    # DBI specs allows us to defer until the first 'execute'.
    my($sth) = DBI::_new_sth($dbh, { proxy_statement => $stmt,
				     proxy_params => [] });
    $sth;
}


package DBD::Proxy::st; # ====== STATEMENT ======

$DBD::Proxy::st::imp_data_size = 0;

use vars qw(%ATTR);

%ATTR = (
    'Warn' => 'local',
    'Active' => 'local',
    'Kids' => 'local',
    'CachedKids' => 'local',
    'PrintError' => 'local',
    'RaiseError' => 'local',
    'NULLABLE' => 'cached',
    'NAME' => 'cached',
    'TYPE' => 'cached',
    'PRECISION' => 'cached',
    'SCALE' => 'cached',
    'NUM_OF_FIELDS' => 'cached',
    'NUM_OF_PARAM' => 'cached'
);

sub execute ($@) {
    my($sth, @params) = @_;

    my $dbh = $sth->{'Database'};
    my $client = $dbh->{'proxy_client'};

    $sth->{'proxy_attr_cache'} = {};
    undef $sth->{'proxy_data'};

    if (!$sth->{proxy_sth}) {
	my($status, $rsth, $numRows, $numFields, $numParam) =
	    $client->CallInt('method', $dbh->{'proxy_dbh'}, 'prepare',
			     $sth->{'proxy_statement'},
			     @params ? [@params] : $sth->{'proxy_params'});
	if (!$status) {
	    DBI::set_err($sth, 1, $rsth);
	    return undef;
	}
	$sth->{'proxy_sth'} = $rsth;
 	$sth->{'proxy_attr_cache'}->{'NUM_OF_FIELDS'} = $numFields;
 	$sth->DBD::_::st::STORE('NUM_OF_FIELDS', $numFields);
 	$sth->{'proxy_attr_cache'}->{'NUM_OF_PARAMS'} = $numParam;
 	$sth->DBD::_::st::STORE('NUM_OF_PARAMS', $numParam);
	$sth->{'proxy_rows'} = $numRows;
    } else {
	my($status, $numRows) =
	    $client->CallInt('method', $sth->{'proxy_sth'}, 'execute',
			    @params ? [@params] : $sth->{'proxy_params'});
	if (!$status) {
	    DBI::set_err($sth, 1, $numRows);
	    return undef;
	}
	$sth->{'proxy_rows'} = $numRows;
    }

    undef $sth->{'proxy_finished'}; # Not a delete because of a bug in DBI

    $sth->{'proxy_rows'} || '0E0';
}

sub fetch ($) {
    my($sth) = shift;

    my($data) = $sth->{'proxy_data'};

    if(!$data) {
	if ($sth->{'proxy_finished'}) { return undef }

	my $rsth = $sth->{'proxy_sth'};
	if (!$rsth) {
	    die "Attempt to fetch row without execute";
	}
	my $dbh = $sth->{Database};
	my $num_rows = $sth->{'proxy_cache_rows'} ||
	    $dbh->{'proxy_cache_rows'} || 20;
	my($status, @rows) = $dbh->{'proxy_client'}->CallInt('method', $rsth,
							     'fetch',
							     $num_rows);
	if (!$status) {
	    DBI::set_err($sth, 1, $rows[0]);
	    return undef;
	}

	if (@rows < $num_rows) {
	    $sth->{'proxy_finished'} = 1;
	    if (!@rows) {
		$sth->finish();
		return undef;
	    }
	}
	$sth->{'proxy_data'} = $data = [@rows];
    }
    my $row = shift @$data;
    if (!@$data) {
	undef $sth->{'proxy_data'};
    }
    $sth->_set_fbav($row);
}
*fetchrow_arrayref = \&fetch;

sub rows ($) {
    my($sth) = @_;
    $sth->{'proxy_rows'};
}

sub finish ($) {
    my($sth) = @_;

    my $rsth = $sth->{'proxy_sth'};
    if ($rsth) {
	my $dbh = $sth->{Database};
	my $no_finish = exists($sth->{'proxy_no_finish'}) ?
	    $sth->{'proxy_no_finish'} : $dbh->{'proxy_no_finish'};
	if (!$no_finish) {
	    my($status, $result) = $dbh->{'proxy_client'}->CallInt('method',
								   $rsth,
								   'finish');
	    if (!$status) {
		DBI::set_err($sth, 1, $result);
		return undef;
	    }
	}
    }
    1;
}

sub DESTROY ($) {
    my($sth) = @_;
    my $rsth = $sth->{'proxy_sth'};
    if ($rsth) {
	my $dbh = $sth->{Database};
	my $no_finish = exists($sth->{'proxy_no_finish'}) ?
	    $sth->{'proxy_no_finish'} : $dbh->{'proxy_no_finish'};
	if (!$no_finish) {
	    $dbh->{'proxy_client'}->CallInt('method', $rsth, 'DESTROY');
	}
    }
    1;
}

sub STORE ($$$) {
    my($sth, $attr, $val) = @_;
    my $type = $ATTR{$attr} || 'remote';

    if ($attr =~ /^proxy_/) {
	$sth->{$attr} = $val;
	return 1;
    }

    if ($type eq 'cached') {
	return 0;
    }

    if ($type eq 'remote') {
	my $dbh = $sth->{'Database'};
	my($status, $result) =
	    $dbh->{'proxy_client'}->CallInt('method', $dbh->{'proxy_dbh'},
					   'STORE', $attr, $val);
	if (!$status) {
	    DBI::set_err($sth, 1, $result);
	    return 0;
	}
	return $result;
    }
    return $sth->DBD::_::st::STORE($attr, $val);
}

sub FETCH ($$) {
    my($sth, $attr) = @_;

    if ($attr =~ /^proxy_/) {
	return $sth->{$attr};
    }

    my $type = $ATTR{$attr} || 'remote';
    if ($type eq 'cached'  &&  exists($sth->{'proxy_attr_cache'}->{$attr})) {
	return $sth->{'proxy_attr_cache'}->{$attr};
    }

    if ($type ne 'local') {
	my $dbh = $sth->{'Database'};
	my($status, $result) =
	    $dbh->{'proxy_client'}->CallInt('method', $sth->{'proxy_sth'},
					   'FETCH', $attr);
	if (!$status) {
	    DBI::set_err($sth, 1, $result);
	    return undef;
	}
	if ($type eq 'cached') {
	    $sth->{'proxy_attr_cache'}->{$attr} = $result;
	}
	return $result;
    }
    return $sth->DBD::_::st::FETCH($attr);
}

sub bind_param ($) {
    my($sth, $param, $val, $type) = @_;
    $sth->{'proxy_param'}->[$param-1] = (@_ > 3) ? $val : [$val, $type];
}


1;

__END__

=head1 NAME

DBD::Proxy - A proxy driver for the DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect("dbi:Proxy:hostname=$host;port=$port;dsn=$db",
                      $user, $passwd);

  # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::Proxy is a Perl module for connecting to a database via a remote
DBI driver. This is of course not needed for DBI drivers which already
support connecting to a remote database, but there are engines which
don't offer network connectivity. Another application is offering
database access through a firewall, as the driver offers query based
restrictions. For example you can restrict queries to exactly those
that are used in a given CGI application.


=head1 CONNECTING TO THE DATABASE

Before connecting to a remote database, you must ensure, that a Proxy
server is running on the remote machine. There's no default port, so
you have to ask your system administrator for the port number. See
L<DBI::ProxyServer(3)> for details.

Say, your Proxy server is running on machine "alpha", port 3334, and
you'd like to connect to an ODBC database called "mydb" as user "joe"
with password "hello". When using DBD::ODBC directly, you'd do a

  $dbh = DBI->connect("DBI:ODBC:mydb", "joe", "hello");

With DBD::Proxy this becomes

  $dsn = "DBI:Proxy:hostname=alpha;port=3334;dsn=DBI:ODBC:mydb";
  $dbh = DBI->connect($dsn, "joe", "hello");

You see, this is mainly the same. The DBD::Proxy module will create a
connection to the Proxy server on "alpha" which in turn will connect
to the ODBC database.

DBD::Proxy's DSN string has the format

  $dsn = "DBI:Proxy:key1=val1; ... ;keyN=valN;dsn=valDSN";

In other words, it is a collection of key/value pairs. The following
keys are recognized:

=over 4

=item hostname

=item port

Hostname and port of the Proxy server; these keys must be present,
no defaults. Example:

    hostname=alpha;port=3334

=item dsn

The value of this attribute will be used as a dsn name by the Proxy
server. Thus it must have the format C<DBI:driver:...>, in particular
it will contain colons. The I<dsn> value may contain semicolons, hence
this key *must* be the last and it's value will be the complete
remaining part of the dsn. Example:

    dsn=DBI:ODBC:mydb

=item cipher

=item key

=item usercipher

=item userkey

By using these fields you can enable encryption. If you set,
for example,

    cipher=$class:key=$key

then DBD::Proxy will create a new cipher object by executing

    $cipherRef = $class->new(pack("H*", $key));

and pass this object to the RPC::pClient module when creating a
client. See L<RPC::pClient(3)>. Example:

    cipher=IDEA:key=97cd2375efa329aceef2098babdc9721

The usercipher/userkey attributes allow you to use two phase encryption:
The cipher/key encryption will be used in the login and authorisation
phase. Once the client is authorised, he will change to usercipher/userkey
encryption. Thus the cipher/key pair is a B<host> based secret, typically
less secure than the usercipher/userkey secret and readable by anyone.
The usercipher/userkey secret is B<your> private secret.

Of course encryption requires an appropriately configured server. See
<DBD::ProxyServer(3)/CONFIGURATION FILE>.

=item debug

Turn on debugging mode

=item proxy_cache_rows

The DBI supports only fetching one or all rows at a time. This is not
appropriate for an application using DBD::Proxy, as one network packet
per result column may slow down things drastically.

Thus the driver is usually fetching a certain number of rows via the
network and caches it for you. By default the value 20 is used, but
you can override it with the I<proxy_cache_rows> attribute. This is
a database handle attribute, but it is inherited and overridable for
the statement handles: Say, you have a table with large blobs, then
you might prefer something like this:

    $sth->prepare("SELECT * FROM images");
    $sth->{'proxy_cache_rows'} = 1;            # Disable caching

=item proxy_no_finish

This attribute is another attempt to reduce network traffic: If the
application is calling $sth->finish() or destroys the statement handle,
then the proxy tells the server to finish or destroy the remote
statement handle. Of course this slows down things quite a lot, but
is prefectly well for avoiding memory leaks with persistent connections.

However, if you set the I<proxy_no_finish> attribute to a TRUE value,
either in the database handle or in the statement handle, then the
finish() or DESTROY() calls will be supressed. This is what you want,
for example, in small and fast CGI applications.

=back


=head1 AUTHOR AND COPYRIGHT

This module is Copyright (c) 1997, 1998

    Jochen Wiedmann
    Am Eisteich 9
    72555 Metzingen
    Germany

    Email: joe@ispsoft.de
    Phone: +49 7123 14887

The DBD::Proxy module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. In particular permission
is granted to Tim Bunce for distributing this as a part of the DBI.


=head1 SEE ALSO

L<DBI(3)>, L<RPC::pClient(3)>, L<Storable(3)>

=cut
