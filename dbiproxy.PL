# -*- perl -*-

my $file = 'dbiproxy';

my $script = <<'SCRIPT';
~startperl~

use strict;

require DBI::ProxyServer;
DBI::ProxyServer::main(@ARGV);
exit(0);


__END__

=head1 NAME

dbiproxy - A proxy server for the DBD::Proxy driver


=head1 SYNOPSIS

    dbiproxy <options> --port <port>


=head1 DESCRIPTION

This tool is just a front end for the DBI::ProxyServer package. All it
does is picking options from the command line and calling
DBI::ProxyServer::main(). See L<DBI::ProxyServer(3)> for details.

Available options include:

=over 4

=item C<--configfile filename>

The DBI::ProxyServer can use a configuration file for authorizing
clients. The file is almost identical to that of RPC::pServer,
with the exception of some additional attributes. See
L<DBI::ProxyServer(3)/CONFIGURATION FILE>.

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

L<DBI::ProxyServer(3)>, L<DBD::Proxy(3)>, L<DBI(3)>

SCRIPT


require Config;
my $config = {};
$config->{'startperl'} = $Config::Config{'startperl'};

$script =~ s/\~(\w+)\~/$config->{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file\n";
}
