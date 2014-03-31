package WikiDOM::Mediawiki::PreprocessorStack;

use WikiDOM::Mediawiki::PreprocessorStackElement;
use strict;

sub new
{
  my $class = shift;
  my $self = {stack => [], top => undef, rootAccum => ''};
  $self->{accum} = \$self->{rootAccum};
  bless $self, $class;
  return $self;
}

sub push
{
  my $self = shift;
  my @args = @_;
  
  my $el;
  if (int(@args) == 1 && ref $args[0] eq 'WikiDOM::Mediawiki::PreprocessorStackElement' )
  {
    $el = $args[0];
  }
  {
    $el = new WikiDOM::Mediawiki::PreprocessorStackElement(@args);
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
sub top
{
  my $self = shift;
  return $self->{top};
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

  my $temp = pop( $self->{stack});

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

1;