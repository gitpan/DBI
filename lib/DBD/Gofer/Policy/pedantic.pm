package DBD::Gofer::Policy::pedantic;

#   $Id: pedantic.pm 9139 2007-02-19 16:45:56Z timbo $
#
#   Copyright (c) 2007, Tim Bunce, Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

our $VERSION = sprintf("0.%06d", q$Revision: 9139 $ =~ /(\d+)/o);

use base qw(DBD::Gofer::Policy::Base);

# the 'pedantic' policy is the same as the Base policy

1;

=head1 AUTHOR AND COPYRIGHT

The DBD::Gofer, DBD::Gofer::* and DBI::Gofer::* modules are
Copyright (c) 2007 Tim Bunce. Ireland.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

