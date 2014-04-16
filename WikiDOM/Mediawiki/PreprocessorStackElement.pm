package WikiDOM::Mediawiki::PreprocessorStackElement;

use strict;
use warnings;

use WikiDOM::Mediawiki::PreprocessorPart;
use WikiDOM::Mediawiki::PhpStrings;

sub new
{
  my $class = shift;
  my $self = {parts=> [new WikiDOM::Mediawiki::PreprocessorPart()]};
  
  my $params = shift;

  my @keys = (
  		'open',		   # // Opening character (\n for heading)
		'close',     	   # // Matching closing character
		'count',            # // Number of opening characters found (number of "=" for heading)
		'parts',            # // Array of PPDPart objects describing pipe-separated parts.
		'lineStart',        # // True if the open char appeared at the start of the input line. Not set for headings.
		'startPos', #?????
);
  foreach my $key (@keys)
  {
    $self->{$key} = $params->{$key} if defined $params->{$key};
    delete $params->{$key};
  }
  die "There are unexpected keys (".join(", ",keys(%$params)).")in params in WikiDOM::Mediawiki::PreprocessorStackElement::new" if keys(%$params);
  bless $self, $class;
  return $self;
}

sub close
{
  my $self = shift;
  return $self->{close};
}

sub open
{
  my $self = shift;
  return $self->{open};
}

sub parts
{
  my $self = shift;
  return $self->{parts};
}

sub lineStart
{
  my $self = shift;
  return $self->{lineStart};
}

sub startPos
{
  my $self = shift;
  return $self->{startPos};
}

sub getAccum
{
  my $self = shift;
  my $part = $self->{parts}->[-1];
  return $part->out();
}

# This function is perl implementation only
sub getObjAccum
{
  my $self = shift;
  my $part = $self->{parts}->[-1];
  return $part->getObjAccum();
}


sub getFlags
{
  my $self = shift;
  
  my $partCount = int (@{$self->{parts}} );
  my $findPipe = $self->{open} ne "\n" && $self->{open} ne '[';
  return {
            'findPipe' => $findPipe,
            'findEquals' => $findPipe && $partCount > 1 && ! defined( $self->{parts}->[-1]->{eqpos} ), # FIXME eqpos not implemented
            'inHeading' => $self->{open} eq "\n",
         }
}

sub getCurrentPart
{
  my $self = shift;
  return $self->{parts}->[-1];
}

sub count
{
  my $self = shift;
  return $self->{count};
}

#/**
# * Get the output string that would result if the close is not found.
# *
# * @return string
# */

sub breakSyntax
{
  my $this = shift;
  my $openingCount = shift || undef;
  my $s;
  if ( $this->open eq "\n" )
  {
    $s = ${$this->parts->[0]->out};
  } else {
    if ( ! defined $openingCount )
    {
      $openingCount = $this->count;
    }
    $s = str_repeat( $this->open, $openingCount );
    my $first = 1;
    foreach my $part ( @{$this->parts} )
    {
      if ( $first )
      {
         $first = 0;
      } else
      {
        $s .= '|';
      }
      $s .= ${$part->out};
    }
  }
  return $s;
}

# this function is perl implementation specific
sub breakSyntaxObj
{
  my $this = shift;
  my $openingCount = shift || undef;
  my @l;
  if ( $this->open eq "\n" )
  {
    @l = @{$this->parts->[0]->getObjAccum()};
  } else {
    if ( ! defined $openingCount )
    {
      $openingCount = $this->count;
    }
    @l = (str_repeat( $this->open, $openingCount ));
    my $first = 1;
    foreach my $part ( @{$this->parts} )
    {
      if ( $first )
      {
         $first = 0;
      } else
      {
         push @l, '|';
      }
      push @l, @{$part->getObjAccum()};
    }
  }
use Data::Dumper;

print Dumper [@l];
  return [@l];
}


sub addPart
{
  my $this = shift;
  my $s = shift || '';
  push @{$this->parts}, new WikiDOM::Mediawiki::PreprocessorPart($s);
}


1;