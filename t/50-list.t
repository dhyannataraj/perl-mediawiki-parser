#!/usr/bin/perl

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use strict;
use warnings;

# use Carp::Always;

use lib "../";

use Mediawiki::Preparser::Stack;
use Mediawiki::Preparser::Stack::Element::Part;

use Test::More 'no_plan';

my $el_data1 = {
  'open' => "«",
  'close' => "»",
  'parts' => [new Mediawiki::Preparser::Stack::Element::Part('Some content')], 
  'startPos' => 1,
  'count' => 2 
};

my $el_data2 = {
  'open' => "(",
  'close' => ")",
  'parts' => [new Mediawiki::Preparser::Stack::Element::Part('Content1'), new Mediawiki::Preparser::Stack::Element::Part('Content2')], 
  'startPos' => 1,
  'count' => 3 
};

my $stack = new Mediawiki::Preparser::Stack();

is ref($stack), 'Mediawiki::Preparser::Stack';
is @{$stack->{'stack'}}, 0;
is $stack->getCurrentPart(), undef;

ok $stack->push ($el_data1);

is @{$stack->{'stack'}}, 1;
my $el = $stack->{'stack'}->[0];
is ref($el), 'Mediawiki::Preparser::Stack::Element';

is ref $el, 'Mediawiki::Preparser::Stack::Element';
ok ($el->{open} eq "«" && $el->{close} eq "»"  && $el->{startPos} == 1 && $el->{count} == 2);
ok (int  @{$el->{parts}} == 1 && ref $el->{parts}->[0] eq 'Mediawiki::Preparser::Stack::Element::Part' && ${$el->{parts}->[0]->out()} eq 'Some content');
is $el->close, "»";
is $el->open, "«";
is $el->count, 2;
is ${$el->getAccum}, 'Some content';
is ${$stack->getAccum}, 'Some content';
my $part;
ok $part = $stack->getCurrentPart();
is ref($part), 'Mediawiki::Preparser::Stack::Element::Part';
is ${$part->out()}, 'Some content';


is $el->breakSyntax(), '««Some content';

ok $stack->push ($el_data2);
is @{$stack->{'stack'}}, 2;
my $el2 = $stack->{'stack'}->[-1];
is $el2, $stack->top();
is ${$el2->getAccum}, 'Content2';
is ${$stack->getAccum}, 'Content2';


is $el2->breakSyntax(), '(((Content1|Content2';

$stack->addPart('Content3');
is $el2->breakSyntax(), '(((Content1|Content2|Content3';

ok $el2 = $stack->pop();
is @{$stack->{'stack'}}, 1;

is $el, $stack->top();

# Now check that accum is accessable evrywhere along the hierarchy
${$el->{parts}->[0]->out()} = '##';
my $accum_ref = $stack->getAccum();
is ($$accum_ref, '##');
$$accum_ref = '$$';
ok( ${$el->{parts}->[0]->out()} eq '$$' && ${$stack->top()->getAccum()} eq '$$' && ${$stack->getAccum()} eq '$$') ;

