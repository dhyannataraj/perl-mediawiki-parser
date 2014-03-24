package WikiDOM::Mediawiki::PreprocessorStack;

use WikiDOM::Mediawiki::PreprocessorStackElement;
use strict;

sub new
{
  my $class = shift;
  my $self = {stack => [], top => undef};
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
  $self->{accum}= $self->{top}->getAccum();
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

1;