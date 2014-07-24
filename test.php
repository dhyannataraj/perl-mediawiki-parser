#!/usr/bin/php

<?php

#echo strcspn('0123456789===ppp','ppp',10);
# echo intval(3/2);

# $i=3; echo $i>0;

# $l =  array(1,2,3,4,5); unset($l[0]); var_dump($l);
# echo substr( '012345', 2, 10);

/*
class test_class {
  var $value;
  function __construct( $value = '' ) {
    $this->value = $value;
  }
}

$o1 = new test_class(1);

$o2 = $o1;

$o3 =& $o1;

$o4 = clone($o1);

$o1->value++;

var_dump($o1);
var_dump($o2);
var_dump($o3);
var_dump($o4);*/



$xmlishRegex = 'pre|nowiki|gallery|rss|includeonly|noinclude|/noinclude|onlyinclude|/onlyinclude';
		$elementsRegex = '~($xmlishRegex)(?:\s|\/>|>)|(!--)~iA';

$text = "!-- dsfdsfdsfdsf -->";


$elementsRegex = '~-([a-z][a-z]).([a-z][a-z][a-z])~';

$text = "---aacddef";



preg_match( $elementsRegex, $text, $matches,PREG_OFFSET_CAPTURE,1 ) ;

var_dump($matches);

?>