#!/bin/bash

log_file=$1
results_html_file=$2

f=$(tempfile)
cat $log_file | subunit-2to1 > $f
/usr/local/bin/subunit2html $f $results_html_file
rm $f
