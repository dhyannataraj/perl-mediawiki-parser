#!/usr/bin/php

<?php
error_reporting(E_ALL);
ini_set("display_errors", "on");


define('WIKIDIR','/.data/home/nataraj/Projects/mediawiki/perl-mediawiki-parser/mediawiki-1.20.3/');
chdir(WIKIDIR);
include WIKIDIR."includes/debug/Debug.php";
include WIKIDIR."includes/Exception.php";
include WIKIDIR."includes/Hooks.php";
include WIKIDIR."includes/GlobalFunctions.php";
include WIKIDIR."includes/parser/Preprocessor.php";
include WIKIDIR."includes/parser/Parser.php";
include WIKIDIR."includes/parser/Preprocessor_DOM.php";

$p = new Parser();
$pp = new Preprocessor_DOM($p);
$text = "==123==
Some paragraph

Second
multiline
parapraph

=== 333 ===
and '''italc''' text
{{test11|test22}}";

#$text="012345";

#$text = '{{context|archaic|lang=fr}}';
# $text = '{{{ {{aaaa}} }}}';
#$text = '{{aaa|bbb=-{{ccc}}-}}';
# $text = '{{aaa|bbb}}';
# $text = '{{ {{aaa}} }}';
#$text = '===aaa==';
#$text = '<pre>{{aaa|{{bbb}} }</pre>';
$text = '{{aaa|==bbb}}';
$text = '===={{aaa====\n';

$text = '{{aaa\n==aaa==\n';

$text = '{{aaa\n==aaa==\n}}';
$text = '{{{{{tplarg_inside_template}}}}}';
$text = 'a<!-- -->b';

$text = 'qqqq<pre/>';


$text = '<rss a="1" b="2"> {{qqqq}}</rss>';

$text = "{{  <!-- Comment breakes templates }}-->\n===<!-- And headers ===\naaa-->bbb";

$text = "Some text\n===<!-- And headers ===\na-->";

$text = "= Header =<!--Comment-->";

$text = "text
  <!--some comment with two spaces after the end of the comment-->  
some more text";

/*
if(isset($argv)){
    if(isset($argv[1]) && $argv[1]){
        $text = $argv[1];
    }elseif(isset($argv[2]) && $argv[2] && file_exists($argv[2])){
        $text = file_get_contents($argv[2]);
    }
}else{ 
    if(isset($_GET['text'])){
        $text = $_GET['text'];
    }
?>

<plaintext>

<?php
}*/



$xml = $pp->preprocessToXml($text);

var_dump ($xml);

#$dom = new DOMDocument;
#$dom->preserveWhiteSpace = FALSE;
#$dom->loadXML($xml);
#$dom->formatOutput = TRUE;
#echo $dom->saveXml();


?>
