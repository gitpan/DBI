package DBI::Gofer::Transport::stream;

#   $Id: stream.pm 9139 2007-02-19 16:45:56Z timbo $
#
#   Copyright (c) 2007, Tim Bunce, Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

use DBI::Gofer::Execute;

use base qw(DBI::Gofer::Transport::pipeone Exporter);

our $VERSION = sprintf("0.%06d", q$Revision: 9139 $ =~ /(\d+)/o);

our @EXPORT = qw(run_stdio_hex);

my $executor = DBI::Gofer::Execute->new();

sub run_stdio_hex {

    my $self = DBI::Gofer::Transport::stream->new();
    local $| = 1;

    #warn "STARTED $$";

    while ( my $frozen_request = <STDIN> ) {

        my $request = $self->thaw_data( pack "H*", $frozen_request );
        my $response = $executor->execute_request( $request );

        my $frozen_response = unpack "H*", $self->freeze_data($response);

        print $frozen_response, "\n"; # autoflushed due to $|=1
    }
}

1;
__END__

=head1 NAME
    
DBI::Gofer::Transport::stream - DBD::Gofer server-side transport for stream
    
=head1 SYNOPSIS

See L<DBD::Gofer::Transport::stream>.

=head1 AUTHOR AND COPYRIGHT

The DBD::Gofer, DBD::Gofer::* and DBI::Gofer::* modules are
Copyright (c) 2007 Tim Bunce. Ireland.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.


=cut

