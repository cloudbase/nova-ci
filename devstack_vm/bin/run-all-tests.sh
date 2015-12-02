#!/bin/bash

tests_dir="/opt/stack/tempest"
parallel_tests=8
max_attempts=3
test_suite="default"
log_file="/home/ubuntu/tempest/subunit-output.log"
results_html_file="/home/ubuntu/tempest/results.html"
tempest_output_file="/home/ubuntu/tempest/tempest-output.log"
subunit_stats_file="/home/ubuntu/tempest/subunit_stats.log"
TEMPEST_DIR="/home/ubuntu/tempest"

basedir="/home/ubuntu/bin"

mkdir -p $TEMPEST_DIR

pushd $basedir

. $basedir/utils.sh

tests_file=$(tempfile)
$basedir/get-tests.sh $tests_dir > $tests_file

echo "Activating virtual env."
set +u
source $tests_dir/.tox/full/bin/activate
set -u

echo "Started running tests."

if [ ! -d "$tests_dir/.testrepository" ]; then
    push_dir
    cd $tests_dir
    echo "Initializing testr"
    testr init
    pop_dir
fi

$basedir/parallel-test-runner.sh $tests_file $tests_dir $log_file \
    $parallel_tests $max_attempts || true

isolated_tests_file=$basedir/isolated-tests.txt
if [ -f "$isolated_tests_file" ]; then
    echo "Running isolated tests from: $isolated_tests_file"
    log_tmp=$(tempfile)
    $basedir/parallel-test-runner.sh $isolated_tests_file $tests_dir $log_tmp \
        $parallel_tests $max_attempts 1 || true

    cat $log_tmp >> $log_file
    rm $log_tmp
fi

rm $tests_file

echo "Generating HTML report..."
$basedir/get-results-html.sh $log_file $results_html_file

cat $log_file | subunit-trace -n -f > $tempest_output_file 2>&1 || true

subunit-stats $log_file > $subunit_stats_file
exit_code=$?

echo "Total execution time: $SECONDS seconds."

popd

exit $exit_code
