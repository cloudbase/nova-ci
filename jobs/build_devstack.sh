#!/bin/bash
#
basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Loading all the needed functions
source $basedir/library.sh

# Loading parameters
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

hyperv01=$1

# add branch to local.sh
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sed -i '3 i\branch=$ZUUL_BRANCH' /home/ubuntu/devstack/local.sh"

#add tested patchset to config.sh
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sed -i '2 i\patch=$ZUUL_CHANGE' /home/ubuntu/bin/config.sh"

run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "echo win_user=$WIN_USER >> /home/ubuntu/bin/config.sh; echo win_pass=$WIN_PASS >> /home/ubuntu/bin/config.sh" 5

# git prep
scp -r -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -i $DEVSTACK_SSH_KEY $basedir/clonemap.yaml ubuntu@$DEVSTACK_IP:/home/ubuntu/
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "pip install zuul==2.5.2"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "/home/ubuntu/.local/bin/zuul-cloner -m /home/ubuntu/clonemap.yaml -v git://git.openstack.org $ZUUL_PROJECT --zuul-branch $ZUUL_BRANCH --zuul-ref $ZUUL_REF --zuul-url $ZUUL_SITE/p --workspace /opt/stack"

# run devstack
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run_devstack.sh $hyperv01 $ZUUL_CHANGE" 5

# run post_stack
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/post_stack.sh" 5

