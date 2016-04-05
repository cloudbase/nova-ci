#!/bin/bash
#

# Loading all the needed functions
source /usr/local/src/nova-ci/jobs/library.sh

# Loading parameters
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

hyperv01=$1
hyperv02=$2

# run devstack
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run_devstack.sh $hyperv01 $hyperv02" 5

# run post_stack
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/post_stack.sh" 5

