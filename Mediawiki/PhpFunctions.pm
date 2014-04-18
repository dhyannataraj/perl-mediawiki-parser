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


1;