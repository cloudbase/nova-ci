source /home/jenkins-slave/tools/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

set +e

ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "mkdir -p /openstack/logs/${hyperv01%%[.]*}"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "mkdir -p /openstack/logs/${hyperv02%%[.]*}"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chown -R nobody:nogroup /openstack/logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chmod -R 777 /openstack/logs"

set -f

run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned Copy-Item -Recurse C:\OpenStack\Log\* \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'systeminfo >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\systeminfo.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'wmic qfe list >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\windows_hotfixes.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'pip freeze >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\pip_freeze.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'ipconfig /all >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\ipconfig.log'

run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-netadapter ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\get_netadapter.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-vmswitch ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\get_vmswitch.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-WmiObject win32_logicaldisk ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\disk_free.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-netfirewallprofile ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\firewall.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-process ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\get_process.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-service ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\get_service.log'

run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'sc qc nova-compute >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\nova_compute_service.log'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'sc qc neutron-hyperv-agent >> \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\neutron_hyperv_agent_service.log'

run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned Copy-Item -Recurse C:\OpenStack\Log\* \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'systeminfo >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\systeminfo.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'wmic qfe list >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\windows_hotfixes.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'pip freeze >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\pip_freeze.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'ipconfig /all >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\ipconfig.log'

run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-netadapter ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\get_netadapter.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-vmswitch ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\get_vmswitch.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-WmiObject win32_logicaldisk ^| Select-object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\disk_free.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-netfirewallprofile ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\firewall.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-process ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\get_process.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned get-service ^| Select-Object * >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\get_service.log'

run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'sc qc nova-compute >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\nova_compute_service.log'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'sc qc neutron-hyperv-agent >> \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\neutron_hyperv_agent_service.log'

set +f
echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

if [ "$IS_DEBUG_JOB" != "yes" ]
	then
		
		#logging the fact that the hyper-v nodes are being freed
		jen_date=$(date +%d/%m/%Y-%H:%M:%S)
		echo "Detaching and cleaning Hyper-V node 1"
		teardown_hyperv $hyperv01 $WIN_USER $WIN_PASS
		echo "$jen_date;$ZUUL_PROJECT;$ZUUL_BRANCH;$ZUUL_CHANGE;$ZUUL_PATCHSET;$hyperv01;FREE" >> /home/jenkins-slave/hypervnodes.log
		
		jen_date=$(date +%d/%m/%Y-%H:%M:%S)
		echo "Detaching and cleaning Hyper-V node 2"
		teardown_hyperv $hyperv02 $WIN_USER $WIN_PASS
		echo "$jen_date;$ZUUL_PROJECT;$ZUUL_BRANCH;$ZUUL_CHANGE;$ZUUL_PATCHSET;$hyperv02;FREE" >> /home/jenkins-slave/hypervnodes.log
		
		
		echo "Creating logs destination folder"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

		echo "Downloading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

		echo "Uploading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz
		gzip -9 /home/jenkins-slave/logs/console-$NAME.log
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/console.log.gz && rm -f /home/jenkins-slave/logs/console-$NAME.log.gz

		echo "Extracting logs"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/"
    
		echo "Fixing permissions on all log files"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET"
    
		echo "Releasing devstack floating IP"
		nova remove-floating-ip "$NAME" "$FLOATING_IP"
		echo "Removing devstack VM"
		nova delete "$NAME"
		/usr/local/src/nova-ci/vlan_allocation.py -r $NAME
		echo "Deleting devstack floating IP"
		nova floating-ip-delete "$FLOATING_IP"
		rm -f /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
	else
		TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
        echo "Creating logs destination folder"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP ]; then mkdir -p /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP; else rm -rf /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/*; fi"

		echo "Downloading logs"
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

		echo "Uploading logs"
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz
        gzip -9 /home/jenkins-slave/logs/console-$NAME.log
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/console.log.gz && rm -f /home/jenkins-slave/logs/console-$NAME.log.gz

		echo "Extracting logs"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz -C /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/"

		echo "Fixing permissions on all log files"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/debug/nova/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP"    
fi

set -e
