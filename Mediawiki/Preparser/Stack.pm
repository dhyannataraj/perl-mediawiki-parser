package Mediawiki::Preparser::Stack;

use Mediawiki::Preparser::Stack::Element;
use strict;

sub new
{
  my $class = shift;
  my $self = {stack => [], top => undef, rootAccum => '', rootObjAccum => []};
  $self->{accum} = \$self->{rootAccum};
  bless $self, $class;
  return $self;
}

sub push
{
  my $self = shift;
  my @args = @_;
  
  my $el;
  if (int(@args) == 1 && ref $args[0] eq 'Mediawiki::Preparser::Stack::Element' )
  {
    $el = $args[0];
  }
  {
    $el = new Mediawiki::Preparser::Stack::Element(@args);
  }
  push @{$self->{stack}}, $el;
  $self->{top} = $el;
  $self->{accum} = $self->{top}->getAccum();
}

sub getAccum
{
  my $self = shift;
  return $self->{accum};
}

# This function is perl implementation only
sub getObjAccum
{
  my $self = shift;
  my $top  = $self->top();
  return $top->getObjAccum if $top;
  return $self->{rootObjAccum};
}

# This function is perl implementation only
sub appendObjAccum
{
  my $self = shift;
  my $value = shift;
  my $opt = shift || {};

  my $part = $self->getCurrentPart();

  if ($value eq '=' && $opt->{special_equal})
  {
    $part->{eqindex} = @{$part->{obj_accum}}
  }
  my $accum = $self->getObjAccum();
  if (ref $value eq 'ARRAY')
  {
    foreach (@$value)
    {
      $self->appendObjAccum($_);
    }
  } else
  {
    if ( @{$accum} && ref($accum->[-1]) eq '' && ref($value) eq '' 
         && ! $opt->{special_equal} && ( ! defined $part->{eqindex} || $part->{eqindex} != int(@$accum)-1) # we are not dealing whith spesial "=" case
       )
    {
      #both last element and the value are texts, so we join them
      $accum->[-1].=$value;
    } else
    {
      push @{$accum}, $value;
    }
  }
}

sub top
{
  my $self = shift;
  return $self->{top};
}
sub stack
{
  my $self = shift;
  return $self->{stack};
}

sub getFlags
{
  my $self = shift;
  if ( ! @{$self->{stack}})
  {
    return {
             'findEquals' => undef,
             'findPipe' => undef,
             'inHeading' => undef,
           }
  }
  return $self->top()->getFlags();
}

sub pop
{
  my $self = shift;
  die 'no elements remaining' unless @{$self->{stack}};

  my $temp = pop($self->{stack});

  if ( @{$self->{stack}} )
  {
    $self->{top} = $self->{stack}->[-1];
    $self->{accum} = $self->{top}->getAccum();
  } else
  {
    $self->{top} = undef;
    $self->{accum} = \$self->{rootAccum};
  }

  return $temp;
}

sub addPart
{
  my $this = shift;
  my $s = shift;
  $this->top->addPart( $s );
  $this->{accum} = $this->{top}->getAccum();
}

sub getCurrentPart
{
  my $this = shift;
  if ( ! $this->{top} )
  {
    return undef;
  } else {
    return $this->{top}->getCurrentPart();
  }
}

# this function is perl implementation specific
sub breakSyntaxObj
{
  my $self = shift;
  my @l = ();
  while ( @{$self->{stack}} )
  {
    my $piece = $self->pop();
    unshift @l, $piece->breakSyntaxObj();
  }
  foreach (@l)
  {
    $self->appendObjAccum($_);
  }
}

1;