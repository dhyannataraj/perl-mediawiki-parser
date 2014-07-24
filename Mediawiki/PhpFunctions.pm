package Mediawiki::PhpFunctions;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
strspn
strlen
strcspn
strrev
str_repeat
htmlspecialchars
isset
empty
min
intval
array_key_exists
preg_match
strpos
strtolower
in_array
preg_quote
);


sub strspn
{
   my $subject = shift;
   my $mask = shift;
   my $start = shift || 0;
   my $length = shift || undef;
   
   $start = length($subject) + $start if $start<0;

   my @amask = split //, $mask;
   my $count=0;
   while ($count+$start<=length($subject) && (! $length || $count < $length))
   {
     my $found = 0;
     my $char = substr($subject, $start+$count,1);
     
     for (my $i=0; $i<=$#amask;$i++)
     {
       if ($char eq $amask[$i])
       {
         $found = 1;
       }

     }
     last unless $found;
     $count ++;
   }
  return $count;
}

sub strlen
{
  my $text = shift;
  return length ($text);
}

sub strcspn
{
  my $str = shift;
  my $chars = shift;
  my $start = shift || 0;
  
  $str = substr $str, $start;
  
  # we search for the position of each character and choose the minimum
  my $res = length($str);
  foreach my $char (split //,$chars)
  {
    my $i = index($str,$char);
    $res = $i if $i>-1 && $res>$i;
  }
  return $res;
}

# strrev — Reverse a string

sub strrev
{
  my @chars = split //, shift;
  return join('',reverse @chars);
}

# str_repeat — Repeat a string

sub str_repeat
{
  my $input = shift;
  my $multiplier = shift;
  
  return $input x $multiplier;
}

sub htmlspecialchars
{
  my $string = shift;
  warn 'htmlspecialchars does not suppport any additional parametrs, exept first one.' if @_;
  $string =~ s/&/&amp;/gs;
  $string =~ s/"/&quot;/gs; #"
#  $string =~ s/'/&#039;/gs; #" #should not do it unless flag ENT_QUOTES is set, but flags are not supported, so do nothing
  $string =~ s/</&lt;/gs; 
  $string =~ s/>/&gt;/gs; 
  return $string;
}

sub isset
{
  return defined shift;
}

# empty
#
# Returns FALSE if var exists and has a non-empty, non-zero value. Otherwise returns TRUE.
#
# The following things are considered to be empty:
#
# "" (an empty string)
# 0 (0 as an integer)
# 0.0 (0 as a float)
# "0" (0 as a string)
# NULL
# FALSE
# array() (an empty array)
# $var; (a variable declared, but without a value)
# http://php.net/manual/en/function.empty.php
sub empty
{
  return ! shift;
}


sub min
{
  my @l = @_;
  my $min = $l[0];
  foreach my $el (@l)
  {
    $min = $el if $el<$min;
  }
  return $min;
}

sub intval
{
  return int(shift);
}

sub array_key_exists
{
  my $key = shift;
  my $hash = shift;
  return defined $hash->{$key};
}



# preg_match — Perform a regular expression match

# Description

# int preg_match ( string $pattern , string $subject [, array &$matches [, int $flags = 0 [, int $offset = 0 ]]] )
# Searches subject for a match to the regular expression given in pattern.


sub preg_match
{
  my $pattern = shift;
  my $subject = shift;
  my $matches = shift;
  my $flags = shift || '';
  my $offset = shift || 0;
  
  die "\$matches should always be ARRAY REF" if ref $matches ne 'ARRAY';

  while (@$matches) # make shure that $matches is empty or clean it
  {
    shift @$matches;
  }
  $subject = substr $subject, $offset if $offset;
  
  # Here goes some dark magic:
  # We get patterns like /(something) to parse/i so
  # We subst it to a program that performs this pattern search
  # and stores it to an array as an original PHP function does
  # In order to get number of parenthesized groups we use @+ (see perlreref)
  # In order to get each group value, we use eval inside eval that pushes ${N} to a result array

  my $program = "\$subject =~ m$pattern;
  my \$count = \$#-;     # see perlreref for more info about @-
  
  if ( \$count>0 )
  {
    my \$val = \$&;
    \$val = [\$val,\$-[0]+\$offset] if \$flags eq 'PREG_OFFSET_CAPTURE';
    push \@\$matches, \$val;
  
    foreach my \$i (1..\$count)
    {
      eval '\$val = \$'.\$i.';';
      die  \$\@ if \$\@;
      if (\$flags eq 'PREG_OFFSET_CAPTURE')
      {
        \$val = [\$val,\$-[\$i]+\$offset];
      }
      push \@\$matches, \$val
    }
  }
  ";

  eval $program;
  die $@ if $@;
  
  return 1 if @$matches; 
  return 0;
}

#strpos — Find the position of the first occurrence of a substring in a string

#Description

#mixed strpos ( string $haystack , mixed $needle [, int $offset = 0 ] )
#Find the numeric position of the first occurrence of needle in the haystack string.

#haystack
#The string to search in.

#needle
#If needle is not a string, it is converted to an integer and applied as the ordinal value of a character.

#offset
#If specified, search will start this number of characters counted from the beginning of the string. Unlike strrpos() and strripos(), the offset cannot be negative.

#Return Values

#Returns the position of where the needle exists relative to the beginning of the haystack string (independent of offset). Also note that string positions start at 0, and not 1.

#Returns FALSE if the needle was not found.

sub strpos
{
  my $haystack = shift;
  my $needle = shift;
  my $offset = shift;
  
  my $res;
  $res  = index ($haystack, $needle, $offset) if defined $offset;
  $res  = index ($haystack, $needle) unless defined $offset;
  return undef if $res == -1;
  return $res;
  
}

sub strtolower
{
  my $str = shift;
  return lc($str);
}

#in_array

#Checks if a value exists in an array

#Description

#bool in_array ( mixed $needle , array $haystack [, bool $strict = FALSE ] )
#Searches haystack for needle using loose comparison unless strict is set.

#[......]

#Return Values

#Returns TRUE if needle is found in the array, FALSE otherwise.

sub in_array
{
  my $needle = shift;
  my $haystack = shift;

  die 'haystack shoudl be array ref!' if ref $haystack ne 'ARRAY';
  foreach my $item (@$haystack)
  {
    return 1 if $needle eq $item;
  }
  return 0;
}

#preg_quote

#Quote regular expression characters

#Description

#string preg_quote ( string $str [, string $delimiter = NULL ] )
#preg_quote takes str and puts a backslash in front of every character that is part of the regular expression syntax. This is useful if you have a run-time string that you need to match in some text and the string may contain special regex characters.

#The special regular expression characters are: . \ + * ? [ ^ ] $ ( ) { } = ! < > | : -

#Parameters

#str
#The input string.

#delimiter
#If the optional delimiter is specified, it will also be escaped. This is useful for escaping the delimiter that is required by the PCRE functions. The / is the most commonly used delimiter.

#Return Values

#Returns the quoted (escaped) string.

sub preg_quote
{
  my $str = shift;
  my $delimiter = shift;
  
  my %chars = split //, '. \ + * ? [ ^ ] $ ( ) { } = ! < > | : - ';
  my @letters = split //, $str;
  my $res = '';
  foreach my $letter (@letters)
  {
    if ($chars{$letter} || (defined $delimiter && $delimiter eq $letter) )
    {
      $res.='\\';
    }
    $res.=$letter;
  }
  return $res;
}
1;