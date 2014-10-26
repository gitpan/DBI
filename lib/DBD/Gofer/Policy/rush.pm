package DBD::Gofer::Policy::rush;

#   $Id: rush.pm 9152 2007-02-22 01:44:25Z timbo $
#
#   Copyright (c) 2007, Tim Bunce, Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

our $VERSION = sprintf("0.%06d", q$Revision: 9152 $ =~ /(\d+)/o);

use base qw(DBD::Gofer::Policy::Base);

__PACKAGE__->create_default_policy_subs({

    # Skipping the connect check is fast, but it also skips
    # fetching the remote dbh attributes!
    # Make sure that your application doesn't need access to dbh attributes.
    skip_connect_check => 1,

    # most code doesn't rely on sth attributes being set after prepare
    skip_prepare_check => 1,

    # ping is almost meaningless for DBD::Gofer and most transports anyway
    skip_ping => 1,

    # don't update dbh attributes at all
    dbh_attribute_update => 'none',
    dbh_attribute_list => undef,

});


1;

=head1 AUTHOR AND COPYRIGHT

The DBD::Gofer, DBD::Gofer::* and DBI::Gofer::* modules are
Copyright (c) 2007 Tim Bunce. Ireland.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

