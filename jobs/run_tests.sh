export FAILURE=0
set +e
echo "Running tests"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run_tests.sh --build-for $ZUUL_PROJECT" >> /home/jenkins-slave/logs/console-$NAME.log 2>&1 || export FAILURE=$?
set -e

if [ $FAILURE != 0 ]
then
    exit 1
    echo "Tempest tests failed"
fi
