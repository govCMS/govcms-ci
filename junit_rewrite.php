<?php

$xml = simplexml_load_file(__DIR__.'/upgrade_status.xml');

$xw = xmlwriter_open_memory();
xmlwriter_set_indent($xw, 1);
$res = xmlwriter_set_indent_string($xw, ' ');

xmlwriter_start_document($xw, '1.0', 'UTF-8');
xmlwriter_start_element($xw, 'testsuites');

xmlwriter_start_attribute($xw, 'name');
xmlwriter_text($xw, 'govcms-deprecations');
xmlwriter_end_attribute($xw);

xmlwriter_start_attribute($xw, 'tests');
xmlwriter_text($xw, count($xml));
xmlwriter_end_attribute($xw);

$totalFailures = 0;

foreach ($xml as $x) {
  $totalFailures += count($x->error);
}

// Bail if no failures.
if ($totalFailures == 0) {
  return;
}

xmlwriter_start_attribute($xw, 'failures');
xmlwriter_text($xw, $totalFailures);
xmlwriter_end_attribute($xw);

// Build the individual testsuites.
foreach ($xml as $x) {
  $totalFailures += count($x->error);

  xmlwriter_start_element($xw, 'testsuite');
  xmlwriter_start_attribute($xw, 'name');
  xmlwriter_text($xw, $x->attributes()->name);
  xmlwriter_end_attribute($xw);

  xmlwriter_start_attribute($xw, 'tests');
  xmlwriter_text($xw, count($x));
  xmlwriter_end_attribute($xw);

  xmlwriter_start_attribute($xw, 'failures');
  xmlwriter_text($xw, count($x));
  xmlwriter_end_attribute($xw);

  foreach ($x->error as $err) {
    xmlwriter_start_element($xw, 'testcase');
    xmlwriter_start_attribute($xw, 'name');
    xmlwriter_text($xw,  $err->attributes()->message . " - found on line: " . $err->attributes()->line);
    xmlwriter_end_attribute($xw);

    xmlwriter_start_attribute($xw, 'file');
    xmlwriter_text($xw, $x->attributes()->name);
    xmlwriter_end_attribute($xw);

    xmlwriter_start_attribute($xw, 'classname');
    xmlwriter_text($xw, "GovCMS deprecation alerts");
    xmlwriter_end_attribute($xw);

    xmlwriter_start_element($xw, 'failure');
    xmlwriter_start_attribute($xw, 'message');
    xmlwriter_text($xw, $err->attributes()->message);
    xmlwriter_end_attribute($xw);

    xmlwriter_end_element($xw); // end failure
    xmlwriter_end_element($xw); // end testcase
  }

  xmlwriter_end_element($xw);
}

xmlwriter_end_element($xw);

xmlwriter_end_document($xw);
echo xmlwriter_output_memory($xw);

