package DBD::Gofer::Policy::classic;

#   $Id: classic.pm 9391 2007-04-10 15:16:05Z timbo $
#
#   Copyright (c) 2007, Tim Bunce, Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

our $VERSION = sprintf("0.%06d", q$Revision: 9391 $ =~ /(\d+)/o);

use base qw(DBD::Gofer::Policy::Base);

__PACKAGE__->create_policy_subs({

    # always use connect_cached on server
    connect_method => 'connect_cached',

    # use same methods on server as is called on client
    prepare_method => '',

    # don't skip the connect check since that also sets dbh attributes
    # although this makes connect more expensive, that's partly offset
    # by skip_ping=>1 below, which makes connect_cached very fast.
    skip_connect_check => 0,

    # most code doesn't rely on sth attributes being set after prepare
    skip_prepare_check => 1,

    # we're happy to use local method if that's the same as the remote
    skip_default_methods => 1,

    # ping is not important for DBD::Gofer and most transports
    skip_ping => 1,

    # only update dbh attributes on first contact with server
    dbh_attribute_update => 'first',

    # we'd like to set locally_* but can't because drivers differ

    # get_info results usually don't change
    cache_get_info => 1,
});


1;

=head1 AUTHOR AND COPYRIGHT

The DBD::Gofer, DBD::Gofer::* and DBI::Gofer::* modules are
Copyright (c) 2007 Tim Bunce. Ireland.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

