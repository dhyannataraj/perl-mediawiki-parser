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

=cut
my $s = '----------------12345za';
$s=~ m~(1)(2)(3)(4)(5)z(a)~;

use Data::Dumper;
print Dumper [@-];
print Dumper [@+];
print $#+;

print "\n", $&;
print "\n", $0;

#print $&;

=cut
my $str;

$str = "sdf\n\n<!-- dsf '<1onlyinclude>  sdfsdfds '</1onlyinclude> -->\nqqqq"; # паррсер чистит вежущий перевод строки, если конец коментария на перевод строки заканчивается...  эту ветку тоже надо тестировать
$str = "{{ sdf<!-- dsf '<1onlyinclude>  sdfsdfds '</1onlyinclude>--> }} "; # ситуация когда комментарий внутри какого-то объекта, -- это отдельная ветка кода


    $str = "=== <!--1--> <!-- But there is a special case when header survives as a single === before comment if there is newline after comment end -->";
    
$str = "text\n  <!-- But there is a special case when header survives as a single === before comment if there is newline after comment end -->  \ntext2";

# погрепать по commentEnd. Какой-то кейс обрабатывается при обработке заголовка. Написать тест и на эту ветку
=cut
$str = "aaaa<onlyinclude>  sdfsdfds '</onlyinclude>";

$str = "aaaa<pre/>"; # Это отдельный случай, и inner в этом случае должен быть null/undef;

$str = "aaaa<pre>qqqqqq</pre>";

$str = "aaaa<noinclude>  sdfsdfds '</noinclude>";

$str = "aaaa<rss>qqqqqq</rss>";

$str = "aaaa<rss/>bbb";  # тут нету inner в результирующем xml'е

=cut

use Data::Dumper;
print Dumper Mediawiki::Preparser::parse($str,{result=>'obj'});
print Dumper Mediawiki::Preparser::parse($str,);

