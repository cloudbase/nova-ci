#!/bin/bash
#
# Copyright 2013 Cloudbase Solutions Srl
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Loading all the needed functions
source $basedir/library.sh

set -e

ESXI_HOST=$NODE_NAME
OPN_PROJECT=${ZUUL_PROJECT#*/}
DEVSTACK_NAME="dvs-$OPN_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
HV1_NAME="hv1-$OPN_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
if [[ ! -z $IS_DEBUG_JOB ]] && [[ $IS_DEBUG_JOB == "yes" ]]; then
	DEVSTACK_NAME="$DEVSTACK_NAME-dbg"
    HV1_NAME="$HV1_NAME-dbg"
    DEBUG="--debug-job"
fi

export DEVSTACK_NAME=$DEVSTACK_NAME
export HV1_NAME=$HV1_NAME
export ESXI_HOST=$ESXI_HOST

echo DEVSTACK_NAME=$DEVSTACK_NAME | tee  /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo HV1_NAME=$HV1_NAME | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ESXI_HOST=$ESXI_HOST | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ZUUL_PROJECT=$ZUUL_PROJECT | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ZUUL_BRANCH=$ZUUL_BRANCH | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ZUUL_CHANGE=$ZUUL_CHANGE | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ZUUL_PATCHSET=$ZUUL_PATCHSET | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo ZUUL_UUID=$ZUUL_UUID | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo IS_DEBUG_JOB=$IS_DEBUG_JOB | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
ZUUL_SITE=`echo "$ZUUL_URL" |sed 's/.\{2\}$//'`
echo ZUUL_SITE=$ZUUL_SITE | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

echo "Deploying devstack $NAME"

# make sure we use latest esxi scripts
scp -r -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -i $DEVSTACK_SSH_KEY $basedir/../esxi/* root@$ESXI_HOST:/vmfs/volumes/datastore1/

# Build the env
run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/build-env.sh --project $ZUUL_PROJECT --zuul-change $ZUUL_CHANGE --zuul-patchset $ZUUL_PATCHSET $LIVE_MIGRATION $DEBUG"
status=$?
if [ $status -ne 0 ]; then
    echo "Something went wrong with the creations of VMs. Bailing out!"
    exit 1
fi
echo "Fetching VMs fixed IP address"

DEVSTACK_IP=$(run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-ip.sh $DEVSTACK_NAME")
HV1_IP=$(run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-ip.sh $HV1_NAME")
#export FIXED_IP="${FIXED_IP//,}"
export DEVSTACK_IP="$DEVSTACK_IP"
export HV1_IP="$HV1_IP"
    
COUNT=1
while [ -z "$DEVSTACK_IP" ] || [ -z "$HV1_IP" ] || [ "$DEVSTACK_IP" == "unset" ] || [ "$HV1_IP" == "unset" ]; do
    if [ $COUNT -lt 10 ]; then
        sleep 15
        DEVSTACK_IP=$(run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-ip.sh $DEVSTACK_NAME")
        HV1_IP=$(run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-ip.sh $HV1_NAME")
        export DEVSTACK_IP="$DEVSTACK_IP"
        export HV1_IP="$HV1_IP"
        COUNT=$(($COUNT + 1))
    else
        echo "Failed to get all fixed IPs"
        echo "We got:"
        echo "$DEVSTACK_NAME has IP $DEVSTACK_IP"
        echo "$HV1_NAME has IP $HV1_IP"
        exit 1
    fi
done

echo "Devstack management IP is : $DEVSTACK_IP"
echo "Hyper-V management IP is : $HV1_IP"

echo "VMs details:"
echo "------------------------------------------------------"
echo "------------------------------------------------------"
echo "DEVSTACK VM:"
run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-details.sh $DEVSTACK_NAME"
echo "------------------------------------------------------"
echo "------------------------------------------------------"
echo "HYPER-V VM:"
run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/get-vm-details.sh $HV1_NAME"
echo "------------------------------------------------------"
echo "------------------------------------------------------"

sleep 60

echo "Probing for connectivity on IP $DEVSTACK_IP"
set +e
wait_for_listening_port $DEVSTACK_IP 22 30
probe_status=$?
set -e
if [ $probe_status -eq 0 ]; then
    VM_OK=0
    echo "VM connectivity OK"
else
    echo "VM connectivity NOT OK, bailing out!"
    exit 1
fi

echo DEVSTACK_IP=$DEVSTACK_IP | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo HV1_IP=$HV1_IP | tee -a /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

# Set ip for data network and bring up the interface
echo "Setting data network IP for $DEVSTACK_NAME to 10.10.1.1/24 on interface eth1" 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo "auto eth1" | sudo tee -a /etc/network/interfaces' 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo "iface eth1 inet static" | sudo tee -a /etc/network/interfaces' 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo "     address 10.10.1.1" | sudo tee -a /etc/network/interfaces' 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo "     netmask 255.255.255.0" | sudo tee -a /etc/network/interfaces' 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'sudo ifup eth1' 1
echo "Network configuration for $DEVSTACK_NAME is:"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'ifconfig -a' 1

# Change devstack hostname to reflect VM name
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo "$DEVSTACK_NAME" | sudo tee /etc/hostname' 1
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost $DEVSTACK_NAME/g" /etc/hosts' 1

#echo "adding $NAME to /etc/hosts"
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'VMNAME=$(hostname); sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost $VMNAME/g" /etc/hosts' 1

echo "clean any apt files:"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sudo rm -rf /var/lib/apt/lists/*" 1

echo "apt-get update:"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sudo apt-get update -y" 1

echo "apt-get upgrade:"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'DEBIAN_FRONTEND=noninteractive && DEBIAN_PRIORITY=critical && sudo apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade' 1
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'DEBIAN_FRONTEND=noninteractive && DEBIAN_PRIORITY=critical && sudo apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" autoremove' 1

run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'DEBIAN_FRONTEND=noninteractive && DEBIAN_PRIORITY=critical && sudo apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install smbclient' 1

# set timezone to UTC
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime" 1

# copy files to devstack
scp -v -r -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -i $DEVSTACK_SSH_KEY $basedir/../devstack_vm/* ubuntu@$DEVSTACK_IP:/home/ubuntu/

if [ "$ZUUL_BRANCH" != "master" ]; then
    run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'echo -e "tempest.api.compute.servers.test_server_rescue.ServerRescueTestJSON.\ntempest.api.compute.servers.test_server_rescue_negative.ServerRescueNegativeTestJSON." >> /home/ubuntu/bin/excluded-tests.txt'
fi

#disable n-crt on master branch
if [ "$ZUUL_BRANCH" == "master" ]; then
    run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sed -i 's/^enable_service n-crt/disable_service n-crt/' /home/ubuntu/devstack/local.conf" 1
fi

set -e

run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sed -i 's/export OS_AUTH_URL.*/export OS_AUTH_URL=http:\/\/127.0.0.1\/identity/g' /home/ubuntu/keystonerc" 3

# update repos
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "/home/ubuntu/bin/update_devstack_repos.sh --branch $ZUUL_BRANCH --build-for $ZUUL_PROJECT" 1

# get locally the vhdx files used by tempest
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "mkdir -p /home/ubuntu/devstack/files/images"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "wget http://144.76.59.195:8088/cirros-0.3.3-x86_64.vhdx -O /home/ubuntu/devstack/files/images/cirros-0.3.3-x86_64.vhdx"
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "wget http://81.181.181.155:8081/shared/images/Fedora-x86_64-20-20140618-sda.vhdx.gz -O /home/ubuntu/devstack/files/images/Fedora-x86_64-20-20140618-sda.vhdx.gz"

# install neutron pip package as it is external
# run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "sudo pip install -U networking-hyperv --pre"

# make local.sh executable
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "chmod a+x /home/ubuntu/devstack/local.sh"

# Preparing share for HyperV logs
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'sudo mkdir /openstack; sudo chown -R ubuntu:ubuntu /openstack'
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'mkdir -p /openstack/logs; chmod 777 /openstack/logs; sudo chown nobody:nogroup /openstack/logs'

# Unzip Fedora image
#echo `date -u +%H:%M:%S` "Started to unzip Fedora image.."
#run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "gzip --decompress --force /home/ubuntu/devstack/files/images/Fedora-x86_64-20-20140618-sda.vhdx.gz"

# Change hyperv hostname to reflect vm name
#run_wsman_cmd $HV1_IP $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned Rename-Computer -NewName "$HV1_NAME" -Restart'
# Wait for hyperv to restart and check connectivity
#run_wsman_cmd_with_retry $HV1_IP $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned ipconfig'

# Create vswitch br100 and add data IP
echo "Creating vswitch br100 on $HV1_NAME"
run_wsman_cmd $HV1_IP $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned New-VMSwitch -Name br100 -AllowManagementOS $true -NetAdapterName \"Ethernet1\"'
echo "Adding IP address 10.10.1.2 to br100 vswitch"
run_wsman_cmd $HV1_IP $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned New-NetIPAddress -InterfaceAlias \"vEthernet (br100)\" -IPAddress \"10.10.1.2\" -PrefixLength 24'

sleep 20

HV1_DATA_IP=$(run_wsman_cmd $HV1_IP $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned (Get-NetIPAddress -InterfaceAlias \"vEthernet (br100)\" -AddressFamily IPv4).IPAddress')
export HV1_DATA_IP=$HV1_DATA_IP

echo "Data IP address for $HV1_NAME is $HV1_DATA_IP"

# Building devstack as a threaded job
echo `date -u +%H:%M:%S` "Started to build devstack as a threaded job"
nohup $basedir/build_devstack.sh $HV1_DATA_IP > /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID.log 2>&1 &
pid_devstack=$!

# Building and joining HyperV nodes
echo `date -u +%H:%M:%S` "Started building & joining Hyper-V node: $HV1_NAME"
nohup $basedir/build_hyperv.sh $HV1_IP > /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID.log 2>&1 &
pid_hv01=$!

TIME_COUNT=0
PROC_COUNT=2

echo `date -u +%H:%M:%S` "Start waiting for parallel init jobs."

finished_devstack=0;
finished_hv01=0;
while [[ $TIME_COUNT -lt 100 ]] && [[ $PROC_COUNT -gt 0 ]]; do
    if [[ $finished_devstack -eq 0 ]]; then
        ps -p $pid_devstack > /dev/null 2>&1 || finished_devstack=$?
        [[ $finished_devstack -ne 0 ]] && PROC_COUNT=$(( $PROC_COUNT - 1 )) && echo `date -u +%H:%M:%S` "Finished building devstack"
    fi
    if [[ $finished_hv01 -eq 0 ]]; then
        ps -p $pid_hv01 > /dev/null 2>&1 || finished_hv01=$?
        [[ $finished_hv01 -ne 0 ]] && PROC_COUNT=$(( $PROC_COUNT - 1 )) && echo `date -u +%H:%M:%S` "Finished building $HV1_NAME"
    fi
    if [[ $PROC_COUNT -gt 0 ]]; then
        sleep 1m
        TIME_COUNT=$(( $TIME_COUNT +1 ))
    fi
done

echo `date -u +%H:%M:%S` "Finished waiting for the parallel init jobs."
echo `date -u +%H:%M:%S` "We looped $TIME_COUNT times, and when finishing we have $PROC_COUNT threads still active"

if [[ ! -z $IS_DEBUG_JOB ]] && [[ $IS_DEBUG_JOB == "yes" ]]
    then
        echo "All build logs can be found in http://cloudbase-ci.com/debug/$OPN_PROJECT/$ZUUL_CHANGE/$ZUUL_PATCHSET/"
    else
        echo "All build logs can be found in http://cloudbase-ci.com/$OPN_PROJECT/$ZUUL_CHANGE/$ZUUL_PATCHSET/"
fi

if [[ $PROC_COUNT -gt 0 ]]; then
    kill -9 $pid_devstack > /dev/null 2>&1
    kill -9 $pid_hv01 > /dev/null 2>&1
    echo "Not all build threads finished in time, initialization process failed."
    exit 1
fi

# HyperV post-build services restart
post_build_restart_hyperv_services $HV1_IP $WIN_USER $WIN_PASS

# Check for nova join (must equal 2)
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'source /home/ubuntu/keystonerc; NOVA_COUNT=$(nova service-list | grep nova-compute | grep -c -w up); if [ "$NOVA_COUNT" != 1 ];then nova service-list; exit 1;fi' 12
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'source /home/ubuntu/keystonerc; nova service-list' 1

# Check for neutron join (must equal 2)
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'source /home/ubuntu/keystonerc; NEUTRON_COUNT=$(neutron agent-list | grep -c "HyperV agent.*:-)"); if [ "$NEUTRON_COUNT" != 1 ];then neutron agent-list; exit 1;fi' 12
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY 'source /home/ubuntu/keystonerc; neutron agent-list' 1

# Call create_cell after init phase is done
if [[ "$ZUUL_BRANCH" == "master" ]] || [[ "$ZUUL_BRANCH" == "stable/ocata" ]]; then
    run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "url=\$(grep transport_url /etc/nova/nova-dhcpbridge.conf | head -1 | awk '{print \$3}'); nova-manage cell_v2 simple_cell_setup --transport-url \$url >> /opt/stack/logs/screen/create_cell.log"
fi

# restart nova services to refresh cached cells (some tests fail because the cell is created before the compute nodes join)
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_IP $DEVSTACK_SSH_KEY "/home/ubuntu/bin/restart_nova_services.sh" 

echo "finished building"
