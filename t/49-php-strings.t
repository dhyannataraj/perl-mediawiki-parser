#!/usr/bin/perl

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use strict;
use warnings;

# use Carp::Always;

use lib "../";

use WikiDOM::Mediawiki::PhpStrings;

use Test::More 'no_plan';


is strspn("1234567890","0321"),3,"strspn_1";
is strspn("1234567890","987"),0,"strspn_2";
is strspn("==","="),2,"strspn_3";
is strspn("1234567890","0321",1),2,"strspn_4";
is strspn("fffffff90","90321",-2),2,"strspn_5";
is strspn("aa=-=-=-=-=-=-=-=-bb","=-",2,4),4,"strspn_3";

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