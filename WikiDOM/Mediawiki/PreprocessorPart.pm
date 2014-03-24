package WikiDOM::Mediawiki::PreprocessorPart;

use strict;
use warnings;
use utf8;

use Data::Alias;

sub new
{
  my $class = shift;
  my $self = {};
  $self->{out}  = shift;
  $self->{out} = '' unless defined $self->{out};
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

1;