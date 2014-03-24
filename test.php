#!/usr/bin/php

<?php

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
var_dump($o4);

?>