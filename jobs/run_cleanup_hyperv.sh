source /home/jenkins-slave/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

set +e

echo "Detaching and cleaning Hyper-V node 1"
teardown_hyperv $hyperv01
echo "Detaching and cleaning Hyper-V node 2"
teardown_hyperv $hyperv02
