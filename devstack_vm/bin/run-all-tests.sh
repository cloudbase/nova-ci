#!/bin/bash

basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $basedir/config.sh
. $DEVSTACK_DIR/functions
mkdir -p $TEMPEST_DIR

pushd $basedir

. $basedir/utils.sh

iniset $TEMPEST_CONFIG compute volume_device_name "sdb"
#iniset $TEMPEST_CONFIG compute min_compute_nodes 2
iniset $TEMPEST_CONFIG compute-feature-enabled rdp_console true
iniset $TEMPEST_CONFIG compute-feature-enabled block_migrate_cinder_iscsi True
iniset $TEMPEST_CONFIG compute-feature-enabled block_migration_for_live_migration True
iniset $TEMPEST_CONFIG compute-feature-enabled live_migration False
iniset $TEMPEST_CONFIG compute-feature-enabled interface_attach False

iniset $TEMPEST_CONFIG scenario img_dir "/home/ubuntu/devstack/files/images/"
iniset $TEMPEST_CONFIG scenario img_file "cirros-0.3.3-x86_64.vhdx"
iniset $TEMPEST_CONFIG scenario img_disk_format vhdx

IMAGE_REF=`iniget $TEMPEST_CONFIG compute image_ref`
iniset $TEMPEST_CONFIG compute image_ref_alt $IMAGE_REF

iniset $TEMPEST_CONFIG compute build_timeout 360
iniset $TEMPEST_CONFIG orchestration build_timeout 360
iniset $TEMPEST_CONFIG volume build_timeout 360
iniset $TEMPEST_CONFIG boto build_timeout 360

iniset $TEMPEST_CONFIG compute ssh_timeout 360
iniset $TEMPEST_CONFIG compute allow_tenant_isolation True

echo "Activating virtual env."
set +u
source $tests_dir/.tox/tempest/bin/activate
pip install -c /opt/stack/requirements/upper-constraints.txt babel
set -u

tests_file=$(tempfile)
$basedir/get-tests.sh $tests_dir > $tests_file

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

rm $tests_file

isolated_tests_list_file=$basedir/isolated-tests.txt
if [ -f "$isolated_tests_list_file" ]; then
    echo `timestamp` "Running isolated tests from: $isolated_tests_list_file"
    isolated_tests_file=$(tempfile)
    $basedir/get-isolated-tests.sh $tests_dir > $isolated_tests_file
    log_tmp=$(tempfile)
    $basedir/parallel-test-runner.sh $isolated_tests_file $tests_dir $log_tmp \
        $parallel_tests $max_attempts 1 || true
    cp $log_tmp /home/ubuntu/tempest/isolated-tests-output.log
    cat $log_tmp >> $log_file
    rm $isolated_tests_file
    rm $log_tmp
fi

echo `timestamp` "Generating HTML report..."
$basedir/get-results-html.sh $log_file $results_html_file

cat $log_file | subunit-trace -n -f > $tempest_output_file 2>&1 || true

subunit-stats $log_file > $subunit_stats_file
exit_code=$?

echo `timestamp` "Total execution time: $SECONDS seconds."

popd

exit $exit_code
