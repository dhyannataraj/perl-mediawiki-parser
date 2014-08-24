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
    src => "===This is not a header too=== because line ends with non equals",
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
  },
  {
    name => 'template_2',
    src => "{{template|{{inside|template}}}}",
    xml => '<root><template><title>template</title><part><name index="1" /><value><template><title>inside</title><part><name index="1" /><value>template</value></part></template></value></part></template></root>',
    obj => [_template('template',[_template('inside',['template'])])]
  },
  {
    name => 'template_3',
    src => "Do not mix {{{template}} with tplarg",
    xml => '<root>Do not mix {<template><title>template</title></template> with tplarg</root>',
    obj => ["Do not mix {",_template("template")," with tplarg"]
  },
  {
    name => 'template_4',
    src => "{{template|param=value_with_second=equal}}",
    xml => '<root><template><title>template</title><part><name>param</name>=<value>value_with_second=equal</value></part></template></root>',
    obj => [_template("template",[['param','=','value_with_second=equal']])]
  },
  {
    name => 'template_5',
    src => "{{template|=param_name_is_empty}}",
    xml => '<root><template><title>template</title><part><name></name>=<value>param_name_is_empty</value></part></template></root>',
    obj => [_template("template",[['=','param_name_is_empty']])]
  },
  {
    name => 'template_6',
    src => "{{unclosed|template",
    xml => '<root>{{unclosed|template</root>',
    obj => ["{{unclosed|template"]
  },

  {
    name => 'template_7',
    src => "{{double {{unclosed|template",
    xml => '<root>{{double {{unclosed|template</root>',
    obj => ["{{double {{unclosed|template"]
  },

  {
    name => 'template_8',
    src => "{{unclosed|template|{{with_good_template_inside}}",
    xml => '<root>{{unclosed|template|<template><title>with_good_template_inside</title></template></root>',
    obj => ["{{unclosed|template|",_template('with_good_template_inside')]
  },
  {
    name => 'template_9',
    src => "{{{{{tplarg_inside_template}}}}}",
    xml => '<root><template><title><tplarg><title>tplarg_inside_template</title></tplarg></title></template></root>',
    obj => [_template(_tplarg('tplarg_inside_template'))]
  },
  {
    # this test really confuses me.
    name => 'template_10',
    src => "{{Inside_a_template\n===Header is still a header O_o===\n}}",
    xml => "<root><template><title>Inside_a_template\n".'<h level="3" i="1">===Header is still a header O_o===</h>'."\n</title></template></root>",
    obj => [_template(["Inside_a_template\n",_header(1,3,20,'Header is still a header O_o'),"\n"])]
  },

  {
    name => 'tplarg_1',
    src => "{{{tplarg}}}",
    xml => '<root><tplarg><title>tplarg</title></tplarg></root>',
    obj => [_tplarg('tplarg')]
  },

  {
    name => 'tplarg_2',
    src => "{{{{{{tplarg}}}}}}",
    xml => '<root><tplarg><title><tplarg><title>tplarg</title></tplarg></title></tplarg></root>',
    obj => [_tplarg(_tplarg('tplarg'))]
  },

# here would be a good idea to take all template tests and clone them as tplarg tests (since it is processed in almost the same way)
# but I am too lazy to do that for now, and since tplarg is processed with the same code as template, template tests will do

  {
    name => 'comment_1',
    src => "123<!-- Test how does unclosed comment works",
    xml => '<root>123<comment>&lt;!-- Test how does unclosed comment works</comment></root>',
    obj => ['123',_comment(3,1,' Test how does unclosed comment works')]
  },
  {
    name => 'comment_2',
    src => "123<!-- Closed comment--> should {{work}}",
    xml => '<root>123<comment>&lt;!-- Closed comment--&gt;</comment> should <template><title>work</title></template></root>',
    obj => ['123',_comment(3,0,' Closed comment'),' should ',_template("work")]
  },
  {
    name => 'comment_3',
    src => "123<!-- Comment should ignore {{templates}} \n==Headers==\n and special tags <noinclude>-->",
    xml => "<root>123<comment>&lt;!-- Comment should ignore {{templates}} \n==Headers==\n and special tags &lt;noinclude&gt;--&gt;</comment></root>",
    obj => ['123',_comment(3,0," Comment should ignore {{templates}} \n==Headers==\n and special tags &lt;noinclude&gt;")]  #FIME we should do something with < --> &lt; transformation
  },

  {
    name => 'comment_4',
    src => "{{  <!-- Comment breakes templates }}-->",
    xml => "<root>{{  <comment>&lt;!-- Comment breakes templates }}--&gt;</comment></root>",
    obj => ['{{  ',_comment(4,0," Comment breakes templates }}")]
  },
  {
    name => 'comment_5',
    src => "=== Headers <!-- Normally is brocken by comments ===\n -->",
    xml => "<root>=== Headers <comment>&lt;!-- Normally is brocken by comments ===\n --&gt;</comment></root>",
    obj => ['=== Headers ', _comment(12,0," Normally is brocken by comments ===\n ")]
  },


  # This test tests mediawiki preparser buggy behaviour: it puts comment inside a header tags, although it should be put after header final tag
  # See https://github.com/dhyannataraj/perl-mediawiki-parser/issues/1 for more info
  {
    name => 'comment_6',
    src => "===<!-- But there is a special case when header survives as a single === before comment if there is newline after comment end -->",
    xml => '<root><h level="1" i="1">===<comment>&lt;!-- But there is a special case when header survives as a single === before comment if there is newline after comment end --&gt;</comment></h></root>',
    obj => [_header(1,1,0,'=',
              _comment(3,0," But there is a special case when header survives as a single === before comment if there is newline after comment end ")
            )
           ]
  },
  {
    name => 'comment_7',
    src => "====<!--1--> <!--2-->  <!--3-->",
    xml => '<root><h level="1" i="1">====<comment>&lt;!--1--&gt;</comment> <comment>&lt;!--2--&gt;</comment>  <comment>&lt;!--3--&gt;</comment></h></root>',
    obj => [_header(1,1,0,'==',
              _comment(4,0,"1"),
              ' ',
              _comment(13,0,"2"),
              '  ',
              _comment(23,0,"3"),
            )
           ]
  },

  {
    name => 'comment_8',
    src => "text\n   <!-- Some full line comment with leading and trailing spaces-->  \nsome more text",
    xml => "<root>text\n<comment>   &lt;!-- Some full line comment with leading and trailing spaces--&gt;  \n</comment>some more text</root>",
    obj => ["text\n   ",
              _comment(8,0," Some full line comment with leading and trailing spaces"),
            "  \nsome more text"
           ]
  },
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

sub _tplarg
{
  my @params = @_;
  my $res = _template(@params);
  $res->{'count'} = 3;
  return $res;
}

sub _comment
{
  my $pos = shift;
  my $unclosed = shift;
  my @rest = @_;
  
  my $res = 

          bless( {
                   'close' => '-->',
                   'open' => '<!--',
                   'startPos' => $pos,
                   'parts' => [
                                bless( {
                                         'obj_accum' => [
                                                          @rest
                                                        ]
                                       }, 'Mediawiki::Preparser::Stack::Element::Part' )
                              ]
                 }, 'Mediawiki::Preparser::Stack::Element' );

  $res->{unclosed} = 1 if $unclosed;
  return $res;
}