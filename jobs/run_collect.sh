source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
source /home/jenkins-slave/tools/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

logs_project=nova

set +e

ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "mkdir -p /openstack/logs/${hyperv01%%[.]*}"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "mkdir -p /openstack/logs/${hyperv02%%[.]*}"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chown -R nobody:nogroup /openstack/logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "sudo chmod -R 777 /openstack/logs"

set -f

run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -ExecutionPolicy RemoteSigned Copy-Item -Recurse C:\OpenStack\Log\* \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned C:\OpenStack\nova-ci\HyperV\scripts\export-eventlog.ps1'
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned cp -Recurse -Container  C:\OpenStack\Logs\Eventlog\* \\'$FLOATING_IP'\openstack\logs\'${hyperv01%%[.]*}'\'

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

run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned C:\OpenStack\nova-ci\HyperV\scripts\export-eventlog.ps1'
run_wsmancmd_with_retry $hyperv02 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned cp -Recurse -Container  C:\OpenStack\Logs\Eventlog\* \\'$FLOATING_IP'\openstack\logs\'${hyperv02%%[.]*}'\'

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
		echo "Creating logs destination folder"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

		echo "Downloading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$VMID.tar.gz"

		echo "Uploading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$VMID.tar.gz" logs@logs.openstack.tld:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz
		gzip -9 /home/jenkins-slave/logs/console-$ZUUL_UUID.log
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz" logs@logs.openstack.tld:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/console.log.gz && rm -f /home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz

		echo "Extracting logs"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/"

		echo "Uploading temporary logs"
                scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv01" logs@logs.openstack.tld:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/hyperv-build-log-$ZUUL_UUID-$hyperv01.log
                scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv02" logs@logs.openstack.tld:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/hyperv-build-log-$ZUUL_UUID-$hyperv02.log
                scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID" logs@logs.openstack.tld:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/devstack-build-log-$ZUUL_UUID.log
    
		echo "Fixing permissions on all log files"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET"

		echo "Removing local copy of aggregate logs"
		rm -fv aggregate-$VMID.tar.gz

                echo "Removing HyperV temporary console logs.."
                rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv01
                rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv02

                echo "Removing temporary devstack log.."
                rm -fv /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID    

	else
		TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
		echo "Creating logs destination folder"
        	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP ]; then mkdir -p /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP; else rm -rf /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/*; fi"

		echo "Downloading logs"
        	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$VMID.tar.gz"

		echo "Uploading logs"
        	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$VMID.tar.gz" logs@logs.openstack.tld:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz
        	gzip -9 /home/jenkins-slave/logs/console-$ZUUL_UUID.log
        	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz" logs@logs.openstack.tld:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/console.log.gz && rm -f /home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz

		echo "Extracting logs"
        	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz -C /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/"

		echo "Uploading temporary logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv01" logs@logs.openstack.tld:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/hyperv-build-log-$ZUUL_UUID-$hyperv01.log
                scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv02" logs@logs.openstack.tld:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/hyperv-build-log-$ZUUL_UUID-$hyperv02.log
                scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID" logs@logs.openstack.tld:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/devstack-build-log-$ZUUL_UUID.log

		echo "Fixing permissions on all log files"
        	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP"

		echo "Removing local copy of aggregate logs"
		rm -fv aggregate-$VMID.tar.gz

                echo "Removing HyperV temporary console logs.."
                rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv01
                rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID-$hyperv02

                echo "Removing temporary devstack log.."
                rm -fv /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID
fi

#Checking the number of iSCSI targets and portals before clean-up
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; Write-Host "[PRE_CLEAN] $env:computername has $targets.count" iSCSI targets'
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; Write-Host "[PRE_CLEAN] $env:computername has $targets.count" iSCSI targets'

python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; Write-Host "[PRE_CLEAN] $env:computername has $targets.count" iSCSI portals'
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; Write-Host "[PRE_CLEAN] $env:computername has $targets.count" iSCSI portals'

echo `date -u +%H:%M:%S` "Started cleaning iSCSI targets and portals"
nohup python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; $ErrorActionPreference = "Continue"; $targets[0].update();' &
pid_clean_targets_hyperv01=$!

nohup python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; $ErrorActionPreference = "Continue" ;$targets[0].update();' &
pid_clean_targets_hyperv02=$!

nohup python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS  'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; foreach ($target in $targets) {$target.remove()}' &
pid_clean_portals_hyperv01=$!

nohup python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS  'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; foreach ($target in $targets) {$target.remove()}' &
pid_clean_portals_hyperv02=$!

#Waiting for iSCSI cleanup
wait $pid_clean_targets_hyperv01
wait $pid_clean_targets_hyperv02
wait $pid_clean_portals_hyperv01
wait $pid_clean_portals_hyperv02

echo `date -u +%H:%M:%S` "Finished cleaning iSCSI targets and portals"

#Checking the number of iSCSI targets and portals after clean-up
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; Write-Host "[POST_CLEAN] $env:computername has $targets.count" iSCSI targets'
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget; Write-Host "[POST_CLEAN] $env:computername has $targets.count" iSCSI targets'

python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; Write-Host "[POST_CLEAN] $env:computername has $targets.count" iSCSI portals'
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell $targets = gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal; Write-Host "[POST_CLEAN] $env:computername has $targets.count" iSCSI portals'

# Restarting MSiSCSI service 
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv01:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell restart-service msiscsi; iscsicli listtargets; iscsicli listtargetportals'
python /home/jenkins-slave/tools/wsman.py -U https://$hyperv02:5986/wsman -u $WIN_USER -p $WIN_PASS 'powershell restart-service msiscsi; iscsicli listtargets; iscsicli listtargetportals'

echo `date -u +%H:%M:%S`
set -e
