source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
export FAILURE=0
set +e
echo "Running tests"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$DEVSTACK_IP "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run-all-tests.sh" >> /home/jenkins-slave/logs/console-$ZUUL_UUID.log 2>&1 || export FAILURE=$?
set -e

if [ $FAILURE != 0 ]
then
    exit 1
    echo "Tempest tests failed"
fi
