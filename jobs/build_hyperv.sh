#!/bin/bash
#
hyperv_node=$1
# Loading all the needed functions
source /usr/local/src/nova-ci/jobs/library.sh

# Loading parameters
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

# building HyperV node
echo $hyperv_node
join_hyperv $hyperv_node $WIN_USER $WIN_PASS

