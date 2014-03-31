package WikiDOM::Mediawiki::PhpStrings;

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
         last;
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
1;