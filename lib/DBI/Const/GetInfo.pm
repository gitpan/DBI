package DBI::Const::GetInfo;

=head1 NAME
 
DBI::Const::GetInfo - Data and functions for describing GetInfo results
 
=head1 SYNOPSIS

The interface to this module is liable to change.

=cut

use DBI::Const::GetInfo::ANSI ();
use DBI::Const::GetInfo::ODBC ();

%InfoTypes =
(
  %DBI::Const::GetInfo::ANSI::InfoTypes
, %DBI::Const::GetInfo::ODBC::InfoTypes
);

%ReturnTypes =
(
  %DBI::Const::GetInfo::ANSI::ReturnTypes
, %DBI::Const::GetInfo::ODBC::ReturnTypes
);

%ReturnValues = ();
{
  my $A = \%DBI::Const::GetInfo::ANSI::ReturnValues;
  my $O = \%DBI::Const::GetInfo::ODBC::ReturnValues;
  while ( my ($k, $v) = each %$A )
  {
    my %h = ( exists $O->{$k} ) ? ( %$v, %{$O->{$k}} ) : %$v;
    $ReturnValues{$k} = \%h;
  }
  while ( my ($k, $v) = each %$O )
  {
    next if exists $A->{$k};
    my %h = %$v;
    $ReturnValues{$k} = \%h;
  }
}
# -----------------------------------------------------------------------------
sub Format
# -----------------------------------------------------------------------------
{
  my $InfoType = shift;
  my $Value    = shift;

  return '' unless defined $Value;

  my $ReturnType = $ReturnTypes{$InfoType};

  return sprintf '0x%08X', $Value if $ReturnType eq 'SQLUINTEGER bitmask';
  return sprintf '0x%08X', $Value if $ReturnType eq 'SQLINTEGER bitmask';
# return '"' . $Value . '"'       if $ReturnType eq 'SQLCHAR';
  return $Value;
}
# -----------------------------------------------------------------------------
sub Explain
# -----------------------------------------------------------------------------
{
  my $InfoType = shift;
  my $Value    = shift;

  return '' unless defined $Value;
  return '' unless exists $ReturnValues{$InfoType};

  $Value = int $Value;
  my $ReturnType = $ReturnTypes{$InfoType};
  my %h = reverse %{$ReturnValues{$InfoType}};

  if ( $ReturnType eq 'SQLUINTEGER bitmask'|| $ReturnType eq 'SQLINTEGER bitmask')
  {
    my @a = ();
    for my $k ( sort { $a <=> $b } keys %h )
    {
      push @a, $h{$k} if $Value & $k;
    }
    return wantarray ? @a : join(' ', @a );
  }
  else
  {
    return $h{$Value} ||'?';
  }
}
# -----------------------------------------------------------------------------
1;
