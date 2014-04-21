#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Mediawiki::Preparser;

use Carp::Always;

=cut
my $text = '== Header ==
Multiline
paragraph

{{template|part1|part2=value2}}

';

# $text = '{{{aaaaa}}'; # Special case {{{ }} are both valid beging and end, but missmatching


# $text ='{{BrockenSyntax|qqq=uuu|222';

$text ='{{{ {{aaa }} }}}';

$text ='[[ aaa ]]';

#'; # В теории должны получать в качестве параметра функции

#WTF?!!
$text = "123{{1122 }}=================


==123==
Some paragraph


";
=cut


#Mediawiki::Preparser::parse("====={{TemplateInHeader}}====\n\nAnd some text");
#Mediawiki::Preparser::parse(" {{TemplateWithCurl|aaa={{bbb|{{{ccc}}");
#Mediawiki::Preparser::parse("{{{aaaa}}");
#Mediawiki::Preparser::parse("==={{aaa}}");
#print Mediawiki::Preparser::parse("=====");
#print Mediawiki::Preparser::parse("{{aaa|bbb=ccc}}");
#print Mediawiki::Preparser::parse("{{aaa|==bbb}}");

use Data::Dumper;
print Dumper Mediawiki::Preparser::parse("{{unterminated|template {{good template}}\n==And then a header==",{result=>'obj'});

