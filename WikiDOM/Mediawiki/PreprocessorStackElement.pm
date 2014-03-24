package WikiDOM::Mediawiki::PreprocessorStackElement;

sub new
{
  my $class = shift;
  my $self = {};
  
  my %params = @_;

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
    $self->{$key} = $params{$key} || undef;
    delete $params{$key};
  }
  die "There are unexpected keys (".join(", ",keys(%params)).")in params in WikiDOM::Mediawiki::PreprocessorStackElement::new" if keys(%params);
  bless $self, $class;
  return $self;
}

sub close
{
  my $self = shift;
  return $self->{close};
}

sub getAccum
{
  my $self = shift;
  my $part = $self->{parts}->[-1];
  return $part->out();
}


1;