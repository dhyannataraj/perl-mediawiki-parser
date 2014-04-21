#!/usr/bin/perl

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use strict;
use warnings;

# use Carp::Always;

use lib "../";

use Mediawiki::Preparser;
use Mediawiki::Preparser::Stack;
use Mediawiki::Preparser::Stack::Element;
use Mediawiki::Preparser::Stack::Element::Part;
use Test::Most 'no_plan';

use Data::Dumper;

my $tests =
[
  {
    name => 'header_1',
    src => "====Header====\nSome Lines",
    xml => '<root><h level="4" i="1">====Header====</h>'."\nSome Lines</root>",
    obj => [_header(1,4,0,'Header'),"\nSome Lines"]
  },
  {
    name => 'header_2',
    src => "====Header {{with|template}}====",
    xml => '<root><h level="4" i="1">====Header <template><title>with</title><part><name index="1" /><value>template</value></part></template>====</h></root>',
    obj => [_header(1,4,0,'Header ',_template('with',['template',]))]
  },
  {
    name => 'header_3',
    src => "====Not closed header is not a header\n",
    xml => "<root>====Not closed header is not a header\n</root>",
    obj => ["====Not closed header is not a header\n"]
  },
  {
    name => 'header_4',
    src => "==========Too many equals header==========",
    xml => '<root><h level="6" i="1">==========Too many equals header==========</h></root>',
    obj => [_header(1,6,0,'====Too many equals header====')]
  },
  {
    name => 'header_5',
    src => "===Leave unmatched equal inside header title==",
    xml => '<root><h level="2" i="1">===Leave unmatched equal inside header title==</h></root>',
    obj => [_header(1,2,0,'=Leave unmatched equal inside header title')]
  },
  {
    name => 'header_6',
    src => "==Leave unmatched equals inside header title====",
    xml => '<root><h level="2" i="1">==Leave unmatched equals inside header title====</h></root>',
    obj => [_header(1,2,0,'Leave unmatched equals inside header title==')]
  },
  {
    name => 'header_7',
    src => "=======", # line full of equals is title with maximum depth level, but leaving = or == as title
    xml => '<root><h level="3" i="1">=======</h></root>',
    obj => [_header(1,3,0,'=')]
  },
  {
    name => 'header_8',
    src => "========", # line full of equals is title with maximum depth level, but leaving = or == as title
    xml => '<root><h level="3" i="1">========</h></root>',
    obj => [_header(1,3,0,'==')]
  },
  {
    name => 'header_9',
    src => "==", # not a header at all
    xml => "<root>==</root>",
    obj => ["=="]
  },
  {
    name => 'header_10',
    src => "=", # not a header at all
    xml => "<root>=</root>",
    obj => ["="]
  },
  {
    name => 'header_11',
    src => "===This is not a header too=== because line ends with non equals", # not a header at all
    xml => "<root>===This is not a header too=== because line ends with non equals</root>",
    obj => ["===This is not a header too=== because line ends with non equals"]
  },
  {
    name => 'header_12',
    src => "====But this====is header!==",
    xml => '<root><h level="2" i="1">====But this====is header!==</h></root>',
    obj => [_header(1,2,0,'==But this====is header!')]
  },
  {
    name => 'header_13',
    src => "=={{unterminaed|template|inside|a|header==",
    xml => '<root>=={{unterminaed|template|inside|a|header==</root>',
    obj => ["=={{unterminaed|template|inside|a|header=="]
  },
  {
    name => 'header_14',
    src => "==text {{good|template}} text {{unterminaed|template|inside|a|header==", # }}
    xml => '<root>==text <template><title>good</title><part><name index="1" /><value>template</value></part></template> text {{unterminaed|template|inside|a|header==</root>', # }}
    obj => ["==text ",_template('good',['template']) ," text {{unterminaed|template|inside|a|header=="]  # }}
  },
  {
    name => 'header_15',
    src => "{{unterminated|template\n==And then a header==", # }}
    xml => '<root>{{unterminated|template'."\n".'<h level="2" i="1">==And then a header==</h></root>', # }}
    obj => ["{{unterminated|template\n",_header(1,2,24,'And then a header')] # }}
  },


  {
    name => 'template_1',
    src => "{{template|param1|param2=value2}}",
    xml => '<root><template><title>template</title><part><name index="1" /><value>param1</value></part><part><name>param2</name>=<value>value2</value></part></template></root>',
    obj => [_template('template',['param1',['param2','=','value2']])]
  }
  
#=cut
#  {
#    name => 'template_1',
#    src => "{{template|param1|aaa{{bbb}}=ccc}}",
#    xml => '<root><h level="4" i="1">====Header====</h>'."\nSome Lines</root>",
#    obj => [_header(1,4,0,'Header'),"\n","Some Lines"]
#  },
#=cut


];



foreach my $test (@$tests)
{
  is Mediawiki::Preparser::parse($test->{src}), $test->{xml}, $test->{name}."_xml";

  my $got = Mediawiki::Preparser::parse($test->{src}, {result=>'obj'});
  my $expected = $test->{obj};
  cmp_deeply ($got, $expected, $test->{name}."_obj") or print STDERR Dumper {got=> $got, expected => $expected};
}



sub _header
{
  my $index = shift;
  my $count = shift;
  my $pos = shift;
  my @rest = @_;
  
  return 

          bless( {
                   'close' => '=',
                   'open' => '=',
                   'header_index' => $index,
                   'count' => $count,
                   'startPos' => $pos,
                   'parts' => [
                                bless( {
                                         'obj_accum' => [
                                                          @rest
                                                        ]
                                       }, 'Mediawiki::Preparser::Stack::Element::Part' )
                              ]
                 }, 'Mediawiki::Preparser::Stack::Element' );

}

sub _template
{
  my $name = shift;
  my $parts = shift || [];

  my $res =  bless( {
                              'open' => '{',
                              'count' => 2,
                              'lineStart' => '',
                              'close' => '}',
                              'parts'=> []
                 }, 'Mediawiki::Preparser::Stack::Element' );

  foreach my $part_data ($name, @$parts)
  {
    my $part = bless( {'obj_accum' => [] }, 'Mediawiki::Preparser::Stack::Element::Part' );
    if (ref $part_data ne 'ARRAY')
    {
      push @{$part->{obj_accum}}, $part_data;
    } else
    {
      my $count = 0;
      foreach my $el (@$part_data)
      {
        push @{$part->{obj_accum}}, $el;
        $part->{eqindex} //= $count if $el eq '=';
        $count ++;
      }
    }
    push @{$res->{parts}}, $part;
  }
  return $res;
}