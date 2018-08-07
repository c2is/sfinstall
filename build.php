<?php
$main = file_get_contents("./sfinstall-tocompile.sh");
$first = file_get_contents("./helpers.sh");

//echo (preg_replace("/\. .abs_path\/install.sh/", $first, $main));
preg_match_all("/^(\. .*)$/m", $main, $matches);
$toReplaceFound=$matches[1];

foreach($toReplaceFound as $toReplace) {
	preg_match("`/(.*$)`m", $toReplace, $matches);
	$fileName = $matches[1];
	echo $toReplace."\n";
	$includeContent = file_get_contents($fileName);
	$includeContent = preg_replace("`#\!/bin/bash`", "", $includeContent);
	$main = str_replace($toReplace, $includeContent, $main);
}
file_put_contents("sfinstall.sh", $main);