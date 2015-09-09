source /home/jenkins-slave/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

set +e

echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

if [ "$IS_DEBUG_JOB" != "yes" ]
	then
		echo "Detaching and cleaning Hyper-V node 1"
		teardown_hyperv $hyperv01
		echo "Detaching and cleaning Hyper-V node 2"
		teardown_hyperv $hyperv02
		echo "Creating logs destination folder"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

		echo "Downloading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

		echo "Uploading logs"
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz
		gzip -9 /home/jenkins-slave/logs/console-$NAME.log
		scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "/home/jenkins-slave/logs/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/console.log.gz && rm -f /home/jenkins-slave/logs/console-$NAME.log.gz

		echo "Extracting logs"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "tar -xzf /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/"
    
		echo "Fixing permissions on all log files"
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "chmod a+rx -R /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET"
    
		echo "Releasing devstack floating IP"
		nova remove-floating-ip "$NAME" "$FLOATING_IP"
		echo "Removing devstack VM"
		nova delete "$NAME"
		/usr/local/src/ci-overcloud-init-scripts/vlan_allocation.py -r $NAME
		echo "Deleting devstack floating IP"
		nova floating-ip-delete "$FLOATING_IP"
		rm -f /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.$JOB_TYPE.txt
	else
		TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
        echo "Creating logs destination folder"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP ]; then mkdir -p /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP; else rm -rf /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/*; fi"

		echo "Downloading logs"
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

		echo "Uploading logs"
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz
        gzip -9 /home/jenkins-slave/logs/console-$NAME.log
        scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "/home/jenkins-slave/logs/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/console.log.gz && rm -f /home/jenkins-slave/logs/console-$NAME.log.gz

		echo "Extracting logs"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "tar -xzf /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz -C /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/"

		echo "Fixing permissions on all log files"
        ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "chmod a+rx -R /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP"    
fi

set -e
