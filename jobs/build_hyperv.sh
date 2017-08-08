#!/bin/bash
#
basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
hyperv_node=$1
# Loading all the needed functions
source $basedir/library.sh

# Loading parameters
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

export LOG_DIR='C:\Openstack\logs\'
export BUILD_DIR='C:\Openstack\build\'

# building HyperV node
echo $hyperv_node
join_hyperv $hyperv_node $WIN_USER $WIN_PASS

