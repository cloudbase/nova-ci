basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
source /home/jenkins-slave/tools/keystonerc_admin
source $basedir/library.sh

echo "devstack_params file:"
ls -lia /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo "devstack params loaded from /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt :"
cat /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo "VM ID: $VMID"
echo "VMs matching that VM ID:"
nova list | grep "$VMID"

set +e

if [ "$IS_DEBUG_JOB" != "yes" ]
    then
        jen_date=$(date +%d/%m/%Y-%H:%M:%S)
        echo "Detaching and cleaning Hyper-V node 1"
        teardown_hyperv $hyperv01 $WIN_USER $WIN_PASS
        echo "$jen_date;$ZUUL_PROJECT;$ZUUL_BRANCH;$ZUUL_CHANGE;$ZUUL_PATCHSET;$hyperv01;FREE" >> /home/jenkins-slave/hypervnodes.log
        
        jen_date=$(date +%d/%m/%Y-%H:%M:%S)
        echo "Detaching and cleaning Hyper-V node 2"
        teardown_hyperv $hyperv02 $WIN_USER $WIN_PASS
        echo "$jen_date;$ZUUL_PROJECT;$ZUUL_BRANCH;$ZUUL_CHANGE;$ZUUL_PATCHSET;$hyperv02;FREE" >> /home/jenkins-slave/hypervnodes.log
        
        echo "Removing devstack VM"
        nova delete "$VMID"
        $basedir/../vlan_allocation.py -r $VMID

        rm -f /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
fi

set -e
