package WikiDOM::Mediawiki::PhpStrings;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
strspn
);


sub strspn
{
   my $subject = shift;
   my $mask = shift;
   my $start = shift;
   my $length = length;
   
   $start = length($subject) + $start if $start<0;
   my @amask = split //, $mask;
   my $count=0;
   while ($count <=$length)
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
   }
}


1;