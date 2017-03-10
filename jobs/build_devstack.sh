#!/bin/bash
#
basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Loading all the needed functions
source $basedir/library.sh

# Loading parameters
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

hyperv01=$1
hyperv02=$2

# add branch to local.sh
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "sed -i '3 i\branch=$ZUUL_BRANCH' /home/ubuntu/devstack/local.sh"

#add tested patchset to config.sh
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "sed -i '2 i\patch=$ZUUL_CHANGE' /home/ubuntu/bin/config.sh"

run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "echo win_user=$WIN_USER >> /home/ubuntu/bin/config.sh; echo win_pass=$WIN_PASS >> /home/ubuntu/bin/config.sh" 5

# run devstack
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run_devstack.sh $hyperv01 $hyperv02 $ZUUL_CHANGE" 5

# run post_stack
run_ssh_cmd_with_retry ubuntu@$FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/post_stack.sh" 5

