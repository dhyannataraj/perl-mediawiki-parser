#!/usr/bin/perl

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use strict;
use warnings;

# use Carp::Always;

use lib "../";

use Mediawiki::PhpFunctions;

use Test::More 'no_plan';


is strspn("1234567890","0321"),3,"strspn_1";
is strspn("1234567890","987"),0,"strspn_2";
is strspn("==","="),2,"strspn_3";
is strspn("1234567890","0321",1),2,"strspn_4";
is strspn("fffffff90","90321",-2),2,"strspn_5";
is strspn("aa=-=-=-=-=-=-=-=-bb","=-",2,4),4,"strspn_6";
is strspn("=}}===","}",1,2),2,"strspn_7";

is strlen('123456'), 6, 'strlen_1';
is strlen(''), 0, 'strlen_2';

# examples from php doc
is strcspn('abcd',  'apple'),0,'strcspn_1';
is strcspn('abcd',  'banana'),0,'strcspn_2';
is strcspn('hello', 'l'),2,'strcspn_3';
is strcspn('hello', 'world'),2,'strcspn_4';
# more tests
is strcspn('0123456789===ppp','ppp',10),3, 'strcspn_5';

is strrev('123456778'),'877654321', 'strrev_1';


is str_repeat('ga',3), 'gagaga', 'str_repeat_1';

is substr( '012345', 2, 10), '2345', 'substr_1';

my $matches = [];
# check it simply work
is preg_match('/(d)(e)f(g)/','abcdefgh',$matches), 1, "preg_match_1";
is_deeply $matches, ['defg','d','e','g'], "preg_match_2";
# now check that it works when $matches is not empty
is preg_match('/(fgh)/','abcdefgh',$matches), 1, "preg_match_3";
is_deeply $matches, ['fgh','fgh'], "preg_match_4";

# now check that it returns 0 when there is no match
is preg_match('/(aaa)/','bbbbb',$matches), 0, "preg_match_5";
is_deeply $matches, [], "preg_match_6";

# chech that it works with ~ instead of /
is preg_match('~(fgh)~','abcdefgh',$matches), 1, "preg_match_7";
is_deeply $matches, ['fgh','fgh'], "preg_match_8";
# check that offset works correctly
is preg_match('~([a-z])~','abcdefgh',$matches,0,1), 1, "preg_match_9";
is_deeply $matches, ['b','b'], "preg_match_10";

is preg_match('~-([a-z][a-z]).([a-z][a-z][a-z])~',"---aacddef",$matches,'PREG_OFFSET_CAPTURE',1),1,"preg_match_11";
is_deeply $matches, [['-aacdde',2],['aa',3],['dde',6]], "preg_match_12";


is strpos('12345abcd',  'ab'),5,'strpos_1';
is strpos('12345abcd',  'zz'),undef,'strpos_2';
is strpos('abcabc',  'ab',1),3,'strpos_3';

is strtolower('AaaAb'),'aaaab', 'strtolower_1';

ok in_array('aaa',['ddd','bbb','aaa']), 'in_array_1';
ok ! in_array('zzz',['ddd','bbb','aaa']), 'in_array_2';

is preg_quote(' a b c d . \ + * ? [ ^ ] $ ( ) { } = ! < > | : -'), ' a b c d \. \\\\ \+ \* \? \[ \^ \] \$ \( \) \{ \} \= \! \< \> \| \: \-', 'preg_quote_1';
is preg_quote('a  [ ^ ]', 'a'), '\a  \[ \^ \]', 'preg_quote_2';

