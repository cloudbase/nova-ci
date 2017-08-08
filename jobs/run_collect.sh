basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
source $basedir/library.sh

LOG_SERVER=cloudbase@cloudbase-ci.com
LOGS_SSH_KEY=$DEVSTACK_SSH_KEY
hyperv01=$HV1_IP
FLOATING_IP=$DEVSTACK_IP

logs_project=nova
set +e
set -f

[ "$IS_DEBUG_JOB" != "yes" ] && run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned Stop-Service nova-compute'
[ "$IS_DEBUG_JOB" != "yes" ] && run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned Stop-Service neutron-hyperv-agent'
#run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned C:\OpenStack\nova-ci\HyperV\scripts\export-eventlog.ps1'
#run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned C:\OpenStack\nova-ci\HyperV\scripts\collect_systemlogs.ps1'
echo "Contents of C:\OpenStack\logs for $hyperv01"
run_wsmancmd_with_retry $hyperv01 $WIN_USER $WIN_PASS 'powershell -executionpolicy remotesigned ls C:\OpenStack\logs'

set +f
echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP "/home/ubuntu/bin/collect_logs.sh $hyperv01 $IS_DEBUG_JOB"

echo "Downloading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$VMID.tar.gz"

gzip -9 /home/jenkins-slave/logs/console-$ZUUL_UUID.log
gzip -9 /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID.log
gzip -9 /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID.log

if [ "$IS_DEBUG_JOB" != "yes" ]
	then
		echo "Creating logs destination folder"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

		echo "Uploading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$VMID.tar.gz" $LOG_SERVER:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/console.log.gz && rm -f /home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz

		echo "Extracting logs"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "tar -xzf /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/"

		echo "Uploading temporary logs"
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/hyperv-build-log-$ZUUL_UUID-$hyperv01.log.gz
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/devstack-build-log-$ZUUL_UUID.log.gz
    
		echo "Fixing permissions on all log files"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "chmod a+rx -R /srv/logs/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET"
	else
		TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
		echo "Creating logs destination folder"
    	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP ]; then mkdir -p /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP; else rm -rf /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/*; fi"

		echo "Uploading logs"
    	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$VMID.tar.gz" $LOG_SERVER:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz
		gzip -9 /home/jenkins-slave/logs/console-$ZUUL_UUID.log
    	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/console.log.gz && rm -f /home/jenkins-slave/logs/console-$ZUUL_UUID.log.gz

		echo "Extracting logs"
        	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "tar -xzf /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz -C /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/"

		echo "Uploading temporary logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/hyperv-build-log-$ZUUL_UUID-$hyperv01.log.gz
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID.log.gz" $LOG_SERVER:/srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/devstack-build-log-$ZUUL_UUID.log.gz

		echo "Fixing permissions on all log files"
    	ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $LOG_SERVER "chmod a+rx -R /srv/logs/debug/$logs_project/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP"
fi

echo "Removing local copy of aggregate logs"
rm -fv aggregate-$VMID.tar.gz

echo "Removing HyperV temporary console logs.."
rm -fv /home/jenkins-slave/logs/hyperv-build-log-$ZUUL_UUID.log.gz

echo "Removing temporary devstack log.."
rm -fv /home/jenkins-slave/logs/devstack-build-log-$ZUUL_UUID.log.gz

echo `date -u +%H:%M:%S`
set -e
