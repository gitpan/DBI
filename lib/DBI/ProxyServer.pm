# -*- perl -*-
#
#   DBI::ProxyServer - a proxy server for DBI drivers
# 
#   Copyright (c) 1997  Jochen Wiedmann
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
# 

require 5.004;
use strict;
require IO::File;
require IO::Socket;
require RPC::pServer;
require DBI;
require DBD::Proxy;
require Getopt::Long;


package DBI::ProxyServer;


############################################################################
#
#   Constants
#
############################################################################

use vars qw($VERSION);

$VERSION = "0.1004";
my $DEFAULT_PID_FILE = '/tmp/dbiproxy.pid';

$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';   # See 'perldoc perlsec'
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};


############################################################################
#
#   Global variables
#
############################################################################

my $debugging = 0;       # Debugging mode on or off (default off)
my $stderr = 0;          # Log to syslog or stderr (default syslog)


############################################################################
#
#   Name:    Msg, Debug, Error, Fatal
#
#   Purpose: Error handling functions
#
#   Inputs:  $msg - message being print, will be formatted with
#                sprintf using the following arguments
#
#   Result:  Fatal() dies, Error() returns without result
#
############################################################################

sub Msg ($$@) {
    my $level = shift;
    my $msg = shift;
    if ($stderr) {
	printf STDERR ($msg, @_);
    } else {
        Sys::Syslog::syslog($level, $msg, @_);
    }
}

sub Debug ($@) {
    if ($debugging) {
	my $msg = shift;
	Msg('debug', $msg, @_);
    }
}

sub Error ($@) {
    my $msg = shift;
    Msg('err', $msg, @_);
}

sub Fatal ($@) {
    my $msg = shift;
    Msg('crit', $msg, @_);
    exit 10;
}


############################################################################
#
#   Name:    ClientConnect
#
#   Purpose: Create a dbh for a client
#
#   Inputs:  $con - server object
#            $ref - reference to the entry in the function table
#                being currently executed
#            $dsn - data source name
#            $uid - user
#            $pwd - password
#
#   Result:  database handle or undef
#
############################################################################

sub ClientConnect ($$$$$) {
    my ($con, $ref, $dsn, $uid, $pwd) = @_;
    my ($dbh);

    $con->Log('debug', "Connecting as '$uid' to '$dsn'");

    if ($uid ne $con->{'user'}) {
	$con->{'error'} = "Nice try, to connect as " . $con->{'user'}
	   . " and login as $uid. ;-)";
	$con->Log('notice', $con->error);
	return (0, $con->{'error'});
    }

    local $ENV{DBI_AUTOPROXY} = ''; # :-)
    if (!defined($dbh = DBI->connect($dsn, $uid, $pwd,
				     { 'PrintError' => 0 }))) {
	my $errMsg = $DBI::errstr;
	$con->{'error'} = "Cannot connect to database: $DBI::errstr";
	return (0, $con->{'error'});
    }

    my ($handle) = RPC::pServer::StoreHandle($con, $ref, $dbh);
    if (!defined($handle)) {
	return (0, $con->error); # StoreHandle did set error message
    }

    Debug("Created dbh as $handle.\n");
    return (1, $handle);
}


############################################################################
#
#   Name:    ClientMethod
#
#   Purpose: Coerce a method for a client
#
#   Inputs:  $con - server object
#            $ref - reference to the entry in the function table
#                being currently executed
#            $handle - object handle
#            $method - method name
#
#   Result:  database handle or undef
#
############################################################################

# Handle binding parameters
sub _BindParams ($$) {
    my($sth, $params) = @_;

    if ($params) {
	my $i = 0;
	while (@$params) {
	    my $value = shift @$params;
	    if (ref($value)) {
		my $type = $value->[1];
		$value = $value->[0];
		Debug("Binding parameter: Type $type, Value $value");
		if (!($sth->bind_param(++$i, $value, $type))) {
		    return "Cannot bind param: " . $sth->errstr;
		}
	    } else {
		Debug("Binding parameter: Value $value");
		if (!($sth->bind_param(++$i, $value))) {
		    return "Cannot bind param: " . $sth->errstr;
		}
	    }
	}
    }
}


sub ClientMethod ($$$$) {
    my ($con, $ref, $handle, $method, @margs) = @_;
    my ($obj) = RPC::pServer::UseHandle($con, $ref, $handle);

    if (!defined($obj)) {
	return (0, $con->error); # UseHandle () stored an error message
    }

    # We could immediately map this to RPC::pServer::CallMethod(),
    # but certain methods need special treatment.
    if ($method eq 'STORE') {
	my ($key, $val) = @margs;
	$obj->{$key} = $val;
	Debug("Client stores value %s as attribute %s for %s",
	      defined($val) ? $val : "undef",
	      defined($key) ? $key : "undef", $handle);
	return (1);
    }
    if ($method eq 'FETCH') {
	my ($key) = @margs;
	my ($val) = $obj->{$key};
	Debug("Client fetches value %s as attribute %s from %s",
	      defined($val) ? $val : "undef",
	      defined($key) ? $key : "undef", $handle);
	return (1, $obj->{$key});
    }
    if ($method eq 'DESTROY') {
	RPC::pServer::DestroyHandle($con, $ref, $handle);
	Debug("Client destroys %s", $handle);
	return (1);
    }

    if (!$obj->can($method)) {
	$con->{'error'} = "Object $handle cannot execute method $method";
	Debug("Client attempt to execute unknown method $method");
	return (0, $con->error);
    }

    if ($method eq 'prepare') {
	my $statement = shift @margs;
	my $params = shift @margs;

	# Check for restricted access
	if ($con->{client}->{sqlRestricted}) {
	    if ($statement =~ /^\s*(\S+)/) {
		my $st = $1;
		if (!($statement = $con->{client}->{$st})) {
		    $con->{'error'} = "Unknown SQL query: $st";
		    return (0, $con->error);
		}
	    } else {
		$con->{'error'} = "Cannot parse restricted SQL statement";
		return (0, $con->error);
	    }
	}

	# We need to execute 'prepare' and 'execute' at once
	my $sth;
	if (!defined($sth = $obj->prepare($statement))) {
	    $con->{'error'} = "Cannot prepare: " . $obj->errstr;
	    return (0, $con->error);
	}

	my $err = _BindParams($sth, $params);
	if ($err) {
	    $con->{'error'} = $err;
	    return (0, $con->error);
	}

	my $rows = $sth->execute();
	if (!$rows) {
	    $con->{'error'} = "Cannot execute: " . $sth->errstr;
	    return (0, $con->error);
	}

	my ($handle) = RPC::pServer::StoreHandle($con, $ref, $sth);
	if (!defined($handle)) {
	    return (0, $con->error); # StoreHandle did set error message
	}

	Debug("Prepare: handle $handle, fields %d, rows %d\n",
	      $sth->{'NUM_OF_FIELDS'}, $sth->rows);
	return (1, $handle, $rows, $sth->{'NUM_OF_FIELDS'},
		$sth->{'NUM_OF_PARAMS'});
    }
    if ($method eq 'execute') {
	my $params = shift @margs;

	my $err = _BindParams($obj, $params);
	if ($err) {
	    $con->{'error'} = $err;
	    return (0, $con->error);
	}

	if (!$obj->execute) {
	    $con->{'error'} = "Cannot execute: " . $obj->errstr;
	    return (0, $con->error);
	}
	Debug("Execute: handle $handle, rows %d\n", $obj->rows);
	return (1, $handle, $obj->rows);
    }
    if ($method eq 'fetch') {
	my $numRows = (shift @margs) || 1;
	my($ref, @rows);
	while ($numRows--  &&  ($ref = $obj->fetchrow_arrayref)) {
	    push(@rows, [@$ref]);
	}
	return (1, @rows);
    }

    #   Default method
    Debug("Client executes method '$method'");
    my ($result) = eval { $obj->$method(@margs) };
    if ($@) {
	$con->{'error'} = "Error while executing $method: $@";
	return (0, $con->error);
    }
    if (!$result  &&  $obj->errstr()) {
	$con->{'error'} = "Error while executing $method: " . $obj->errstr();
    }
    (1);
}


############################################################################
#
#   Name:    Server
#
#   Purpose: Server child's main loop
#
#   Inputs:  $server - server object
#
#   Result:  Nothing, never returns
#
############################################################################

sub Server ($) {
    my ($server) = shift;
    my (%handles);

    # Initialize the function table
    my ($funcTable) = {
	'connect' => { 'code' => \&ClientConnect, 'handles' => \%handles },
	'method'  => { 'code' => \&ClientMethod, 'handles' => \%handles }
    };
    $server->{'funcTable'} = $funcTable;

    while (!$server->{'sock'}->eof()) {
	if ($server->{'sock'}->error()) {
	    exit(1);
	}
	if (!$server->Loop()) {
	    Error("Error while communicating with child: " . $server->error);
	}
    }
    exit(0);
}


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message
#
#   Inputs:  None
#
#   Returns: Nothing, aborts with error status
#
############################################################################

sub Usage () {
    print STDERR <<"USAGE";
Usage: $0 [options]

Possible options are:

  --port <port>		Set port number where the agent should bind to. This
			option is required, no defaults set.
  --ip <ip-number>      Set ip number where the agent should bind to.
                        Defaults to INADDR_ANY, any local ip number.
  --configfile <file>   Set the name of the configuration file that the agent
                        should read upon startup. This file contains host,
                        user and query based authorization and encryption
                        rules and the like.
  --nofork              Supress forking, useful for debugging only.
  --timeout <seconds>   Timeout if idle for this number of seconds.
  --pidfile <file>      Set the name of the file, where the proxy server will
                        store its PID number, ip, port number and other
                        information. This is required mainly for
                        administrative purposes. Default is
                        $DEFAULT_PID_FILE.
  --help		Print this help message.
  --debug		Turn on debugging messages.
  --stderr		Print messages on stderr; defaults to using syslog.
  --version		Print version number and exit.


DBI::ProxyServer $VERSION - the DBI Proxy server
Copyright (C) 1997, 1998 Jochen Wiedmann
see 'perldoc DBI::ProxyServer' for additional information.
USAGE
    exit 0;
}


############################################################################
#
#   Name:    CreatePidFile
#
#   Purpose: Creates PID file
#
#   Inputs:  $sock - socket object being currently used by the server
#            $pidfile - PID file name
#            $commandLine - Program's command line
#
#   Returns: Nothing
#
############################################################################

sub CreatePidFile ($$$) {
    my($sock, $pidFile, $commandLine) = @_;

    my $fh = IO::File->new($pidFile, "w");
    if (!defined($fh)) {
	Error("Cannot create PID file $pidFile: $!");
    } else {
	$fh->printf("$$\nIP number: %s, Port number %s\n$commandLine\n",
		    $sock->sockhost, $sock->sockport);
	$fh->close();
    }
}


############################################################################
#
#   Name:    catchChilds
#
#   Purpose: Signal handler for SIGCHLD.
#
#   Inputs:  None
#
#   Returns: Nothing
#
############################################################################

sub catchChilds () {
    my $pid = wait;
    $SIG{'CHLD'} = \&catchChilds;  # Rumours say, we need to reinitialize
                                   # the handler on System V
}


############################################################################
#
#   This is the proxy server's main part.
#
############################################################################

sub main {
    my @args = @_;
    if (!@args) { @args = @ARGV }
    local (@ARGV) = @args;

    my $commandLine = "$0 " . join(" ", @args);

    my $o = {
	'fork' => 1
    };
    Getopt::Long::GetOptions(
	$o, "--port=s", "--configfile=s", "--fork!",
	"--pidfile=s", "--ip=s", "--debug", "--stderr",
	"--version", "--help", "--facility=s",
	"--timeout=i"
    );

    if ($o->{'version'}) {
	print(<<"MSG");
DBI::ProxyServer $VERSION - the DBI Proxy server,
Copyright (C) 1997, 1998 Jochen Wiedmann

See 'perldoc DBI::ProxyServer' or 'dbiproxy --help' for additional
information.
MSG
        exit 0;
    }
    if ($o->{'help'}  ||  !$o->{'port'}) {
	Usage();
    }
    $debugging = $o->{'debug'};

    #   Initialize debugging and logging
    unless ($o->{stderr}) {
	require Sys::Syslog;
	if (defined(&Sys::Syslog::setlogsock)  &&
	    defined(&Sys::Syslog::_PATH_LOG)) {
	    Sys::Syslog::setlogsock('unix');
	}
	Sys::Syslog::openlog('DBI::ProxyServer', 'pid',
			     ($o->{'facility'} || 'daemon'));
	eval { Sys::Syslog::setlogsock('unix') };
	Sys::Syslog::syslog('info', 'DBI::ProxyServer starting at %s, port %s',
			    ($o->{'ip'} || 'any ip number'), $o->{'port'});
    }

    #   Create an IO::Socket object
    my $sock = IO::Socket::INET->new(
	'Proto' => 'tcp',
	'LocalPort' => $o->{'port'},
	'LocalAddr' => ($o->{'ip'} || undef),
	'Reuse' => 1,
	'Listen' => 5
    );
    if (!defined($sock)) {
	Fatal("Cannot create socket: $!");
    }

    #   Create the PID file
    CreatePidFile($sock, ($o->{'pidfile'} || $DEFAULT_PID_FILE), $commandLine);

    $SIG{'CHLD'} = \&catchChilds;


    #   In a loop, wait for connections.
    while (1) {
	#   Create a RPC::pServer object
	my $server;
	eval {
	    local $SIG{ALRM} = sub { die "Timeout" } if $o->{timeout};
	    alarm $o->{timeout} if $o->{timeout};
	    $server = RPC::pServer->new(
		'sock' => $sock,
		'debug' => $o->{'debug'},
		'stderr' => $o->{'stderr'},
		'configFile' => $o->{'configfile'}
	    );
	    alarm 0 if $o->{timeout};
	};
	Debug("server: $server ($@)");

	eval {
	    if (!ref($server)) {
		Error("Cannot create server object: $server");
		next;
	    }
	    Debug("Client logged in: application = %s, version = %s,"
		  . " user = %s",
		  $server->{'application'}, $server->{'version'},
		  $server->{'user'});

	    my ($client) = $server->{'client'};
	    if (ref($client) ne 'HASH'  &&  $o->{'configfile'}) {
		Error("Server is missing a 'client' object.");
		$server->Deny("Not authorized.");
		next;
	    }

	    my $users = '';
	    if ($client->{'users'}) {
		# Ensure, that first and last user can match \s$user\s
		$users = " " . $client->{'users'} . " ";
	    }
	    if (!defined($server->{'user'})) { $server->{'user'} = ''; }
	    my $user = $server->{'user'};

	    if ($server->{'application'} !~ /^dbi\:[^\:]+\:/i) {
		#   Whatever this client is looking for, it cannot be us :-)
		Debug("Wrong application: " . $server->{'application'});
		$server->Deny("This is a DBI::ProxyServer. Go away!");
	    }
	    elsif ($server->{'version'} > $VERSION) {
		Debug("Wrong version: " . $server->{'version'});
		$server->Deny("Sorry, but I am running version"
			      . " $VERSION");
	    }
	    elsif ($o->{'configfile'}  &&  $users !~ /\s\Q$user\E\s/) {
		Debug("User not permitted: $user");
		$server->Deny("You are not permitted to connect.");
	    }
	    else {
		#   Fork, and enter the main loop.
		my $pid;

		Debug("ok, fork = " . $o->{'fork'});

		if ($o->{'fork'}) {
		    if (!defined($pid = fork())) {
			Error("Cannot fork: $!.");
			$server->Deny("Cannot fork: $!");
		    }
		}
		if (!$o->{'fork'} ||  $pid == 0) {
		    #   I am the child.
		    Debug("Accepting client.");
		    $server->Accept("Welcome, this is the DBI::ProxyServer"
				    . " $VERSION.");

		    #
		    #   Switch to user specific encryption
		    #
		    my $uval;
		    if ($uval = $server->{'client'}->{$user}) {
			if ($uval =~ /encrypt=\"(.*),(.*),(.*)\"/) {
			    my $module = $1;
			    my $class = $2;
			    my $key = $3;
			    my $cipher;
			    eval "use $module;"
				. " \$cipher = $class->new(pack('H*', \$key))";
			    if ($cipher) {
				$server->Encrypt($cipher);
				$server->Log('debug',
					     "Changed encryption to %s",
					     $server->Encrypt());
			    } else {
				$server->Log('err', "Cannot not switch to user"
					     . " specific encryption: $@");
				exit(1);
			    }
			}
		    }

		    Debug("Entering serving loop");

		    Server($server);
		}
	    }
	};
	if ($@) {
	    Error("Eval error: $@");
	}
    }
}


1;


__END__

=head1 NAME

DBI::ProxyServer - a server for the DBD::Proxy driver


=head1 SYNOPSIS

    use DBI::ProxyServer;
    DBI::ProxyServer::main(@ARGV);


=head1 DESCRIPTION

DBI::Proxy Server is a module for implementing a proxy for the DBI
proxy driver, DBD::Proxy. It allows access to databases over the
network if the DBMS does not offer networked operations. But the
proxy server might be useful for you, even if you have a DBMS with
integrated network functionality: It can be used as a DBI proxy in
a firewalled environment.

DBI::ProxyServer runs as a daemon on the machine with the DBMS or on the
firewall. The client connects to the agent using the DBI driver
DBD::Proxy, thus in the exactly same way than using DBD::mysql, DBD::mSQL
or any other DBI driver.

The agent is implemented as a RPC::pServer application. Thus you
have access to all the possibilities of this module, in particular
encryption and a similar configuration file. DBI::ProxyServer adds the
possibility of query restrictions: You can define a set of queries that
a client may execute and restrict access to those. (Requires a DBI
driver that supports parameter binding.) See L</CONFIGURATION FILE>.


=head1 OPTIONS

When calling the DBI::ProxyServer::main() function, you supply an
array of options. (@ARGV, the array of command line options is used,
if you don't.) These options are parsed by the Getopt::Long module.
Available options include:

=over 4

=item C<--configfile filename>

The DBI::ProxyServer can use a configuration file for authorizing
clients. The file is almost identical to that of RPC::pServer,
with the exception of some additional attributes. See
L</CONFIGURATION FILE>.

If you don't use a config file, then access control is completely
disabled. Only use this for debugging purposes or something similar!

=item C<--debug>

Turns on debugging mode. Debugging messages will usually be logged
to syslog with facility I<daemon> unless you use the options
C<--facility> or C<--stderr>, see below.

=item C<--facility>

Sets the syslog facility, by default I<daemon>.

=item C<--help>

Tells the proxy server to print a help message and exit immediately.

=item C<--ip ip-number>

Tells the DBI::ProxyServer, on which ip number he should bind. The
default is, to bind to C<INADDR_ANY> or any ip number of the local
host. You might use this option, for example, on a firewall with
two network interfaces. If your LAN has non public IP numbers and
you bind the proxy server to the inner network interface, then you will
easily disable the access from the outer network or the Internet.

=item C<--port port>

This option tells the DBI::ProxyServer, on which port number he should
bind. Unlike other applications, DBI::ProxyServer has no builtin default,
so using this option is required.

=item C<--pidfile filename>

Tells the daemon, where to store its PID file. The default is
I</tmp/dbiproxy.pid>. The PID file looks like this:

    567
    IP number 127.0.0.1, port 3334
    dbiproxy -ip 127.0.0.1 -p 3334

The first line is the process number. The second line are IP number
and port number, so that they can be used by local clients and the
third line is the command line. These can be used in administrative
scripts, for example to first kill the DBI::ProxyServer and then
restart it with the same options you do a

    kill `head -1 /tmp/dbiproxy.pid`
    `tail -1 /tmp/dbiproxy.pid`

=item C<--stderr>

Forces printing of messages to stderr. The default is using the syslog.

=item C<--version>

Forces the DBI::ProxyServer to print its version number and copyright message
and exit immediately.

=back

=head1 CONFIGURATION FILE

The configuration file is just that of I<RPC::pServer> with some
additional attributes. Currently its own use is authorization and
encryption.

=head2 Syntax

Empty lines and comment lines (starting with hashes, C<#> charactes)
are ignored. All other lines have the syntax

    var value

White space at the beginning and the end of the line will be removed,
so will white space between C<var> and C<val>. On the other hand
C<value> may contain white space, for example

    description Free form text

would be valid with C<value> = C<Free form text>.

=head2 Accepting and refusing hosts

Semantically the configuration file is a collection of host definitions,
each of them starting with

    accept|deny mask

where C<mask> is a Perl regular expression matching host names or IP
numbers (in particular this means that you have to escape dots),
C<accept> tells the server to accept connections from C<mask> and
C<deny> forces to refuse connections from C<mask>. The first match
is used, thus the following will accept connections from 192.168.1.*
only

    accept 192\.168\.1\.
    deny .*

and the following will accept all connections except those from
evil.guys.com:

    deny evil\.guys\.com
    accept .*

Default is to refuse connections, thus the C<deny .*> in the first
example is redundant, but of course good style.

=head2 Host based encryption

You can force a client to use encryption. The following example will
accept connections from 192.168.1.* only, if they are encrypted with
the DES algorithm and the key C<0123456789abcdef>:

    accept 192\.168\.1\.
        encryption DES
        key 0123456789abcdef
        encryptModule Crypt::DES

    deny .*

You are by no means bound to use DES. DBI::ProxyServer just expects a
certain API, namely the methods I<new>, I<keysize>, I<blocksize>,
I<encrypt> and I<decrypt>. For example IDEA is another choice. The
above example will be mapped to this Perl source:

    $encryptModule = "Crypt::DES";
    $encryption = "DES";
    $key = "0123456789abcdef";

    eval "use $encryptModule;"
       . "$crypt = \$encryption->new(pack('H*', \$key));";

I<encryptModule> defaults to I<encryption>, this is only needed because
of the brain damaged design of I<Crypt::IDEA> and I<Crypt::DES>, where
module name and class name differ.

=head2 User based authorization

The I<users> attribute allows to restrict access to certain users.
For example the following allows only the users C<joe> and C<jack>
from host C<alpha> and C<joe> and C<mike> from C<beta>:

    accept alpha
        users joe jack

    accept beta
        users joe mike

=head2 User based encryption

Although host based encryption is fine, you might still wish to force
different users to use different encryption secrets. Here's how it
goes:

    accept alpha
        users joe jack
        jack encrypt="Crypt::DES,DES,fedcba9876543210"
        joe encrypt="Crypt::IDEA,IDEA,0123456789abcdef0123456789abcdef"

This would force jack to encrypt with I<DES> and key C<fedcba9876543210>
and joe with I<IDEA> and C<0123456789abcdef0123456789abcdef>. The three
fields of the I<encrypt> entries correspond to the I<encryptionModule>,
I<encryption> and I<key> attributes of the host based encryption.

You note the problem: Of course user based encryption can only be
used when the user has already logged in. Thus we recommend to use
both host based and user based encryption: The former will be used
in the authorization phase and the latter once the client has logged
in. Without user based secrets the host based secret (if any) will
be used for the complete session.

=head2 Query restrictions

You have the possibility to restrict the queries a client may execute
to a predefined set.

Suggest the following lines in the configuration file:

    accept alpha
        sqlRestrict 1
        insert1 INSERT INTO foo VALUES (?, ?)
        insert2 INSERT INTO bla VALUES (?, ?, ?)

    accept beta
        sqlRestrict 0

This allows users connecting from C<beta> to execute any SQL query, but
users from C<alpha> can only insert values into the tables I<foo> and
I<bar>. Clients select the query by just passing the query name
(I<insert1> and I<insert2> in the example above) as an SQL statement
and binding parameters to the statement. Of course the client side must
know how much parameters should be passed. Thus you should use the
following for inserting values into foo from the client:

    my $dbh;
    my $sth = $dbh->prepare("insert1 (?, ?)");
    $sth->execute(1, "foo");
    $sth->execute(2, "bar");


=head1 AUTHOR

    Copyright (c) 1997    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Email: joe@ispsoft.de
                          Phone: +49 7123 14881

The DBI::ProxyServer module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. In particular
permission is granted to Tim Bunce for distributing this as a part of
the DBI.


=head1 SEE ALSO

L<dbiproxy(1)>, L<DBD::Proxy(3)>, L<DBI(3)>, L<RPC::pServer(3)>,
L<RPC::pClient(3)>, L<Sys::Syslog(3)>, L<syslog(2)>

