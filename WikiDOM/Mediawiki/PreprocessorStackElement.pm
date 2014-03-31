package WikiDOM::Mediawiki::PreprocessorStackElement;

sub new
{
  my $class = shift;
  my $self = {};
  
  my $params = shift;

  my @keys = (
  		'open',		   # // Opening character (\n for heading)
		'close',     	   # // Matching closing character
		'count',            # // Number of opening characters found (number of "=" for heading)
		'parts',            # // Array of PPDPart objects describing pipe-separated parts.
		'lineStart',        # // True if the open char appeared at the start of the input line. Not set for headings.
		'startPos' #?????
);
  foreach my $key (@keys)
  {
    $self->{$key} = $params->{$key} || undef;
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
  return int @{$self->{parts}};
}

1;