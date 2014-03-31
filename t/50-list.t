#!/usr/bin/perl

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use strict;
use warnings;

# use Carp::Always;

use lib "../";

use WikiDOM::Mediawiki::PreprocessorStack;
use WikiDOM::Mediawiki::PreprocessorPart;

use Test::More 'no_plan';


my $stack = new WikiDOM::Mediawiki::PreprocessorStack();

is ref($stack), 'WikiDOM::Mediawiki::PreprocessorStack';
is @{$stack->{'stack'}}, 0;

#example from Preprocessor_DOM.php line 502
ok $stack->push ({
						'open' => "\n",
						'close' => "\n",
						'parts' => [new WikiDOM::Mediawiki::PreprocessorPart('==')], # array( new PPDPart( str_repeat( '=', $count ) ) ),
						'startPos' => 1, # $i,
						'count' => 2 #$count
		});
is @{$stack->{'stack'}}, 1;
my $el = $stack->{'stack'}->[0];
is ref $el, 'WikiDOM::Mediawiki::PreprocessorStackElement';
ok ($el->{open} eq "\n" && $el->{close} eq "\n"  && $el->{startPos} == 1 && $el->{count} == 2);
ok (int  @{$el->{parts}} == 1 && ref $el->{parts}->[0] eq 'WikiDOM::Mediawiki::PreprocessorPart' && ${$el->{parts}->[0]->out()} eq '==');
is $el->close, "\n";
is $el->open, "\n";
is $el->count, 1;

# Now check that accum is accessable evrywhere along the hierarchy
${$el->{parts}->[0]->out()} = '##';
my $accum_ref = $stack->getAccum();
is ($$accum_ref, '##');
$$accum_ref = '$$';

ok( ${$el->{parts}->[0]->out()} eq '$$' && ${$stack->top()->getAccum()} eq '$$' && ${$stack->getAccum()} eq '$$') ;




#use Data::Dumper;
#print  Dumper($stack);

# BEGIN { plan tests => 2 };

#throws_ok {die}
#'VR::Core::Exception', 'record_create_5';

#is $@->code, $ERR_BAD_PARAMS, 'record_create_6';

