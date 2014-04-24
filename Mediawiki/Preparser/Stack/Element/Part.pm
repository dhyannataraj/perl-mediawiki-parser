package Mediawiki::Preparser::Stack::Element::Part;

use strict;
use warnings;
use utf8;

sub new
{
  my $class = shift;
  my $self = {};
  my $data = shift;

  $self->{out} = $data // '';
  $self->{obj_accum} = [];
  push @{$self->{obj_accum}}, $data if defined $data;  # This perl implementation specific 
  bless $self, $class;
  return $self;
}


sub out
{
  my $self = shift;
#  alias my $out = $self->{out};
#  return \$out
   return \$self->{out};
}

# This sub is in perl implementation only
sub getObjAccum
{
  my $self = shift;
  return $self->{obj_accum};
}

sub commentEnd
{
  my $self = shift;
  return $self->{commentEnd};
}

sub visualEnd
{
  my $self = shift;
  return $self->{visualEnd};
}

sub eqpos
{
  my $self = shift;
  return $self->{eqpos};
}

1;