source /home/jenkins-slave/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

set +e

echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

echo "Creating logs destination folder"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "if [ ! -d /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

echo "Downloading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

echo "Uploading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz
gzip -9 /home/jenkins-slave/console-$NAME.log
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem "/home/jenkins-slave/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/console.log.gz && rm -f /home/jenkins-slave/console-$NAME.log.gz

echo "Extracting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "tar -xzf /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/"

echo "Fixing permissions on all log files"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i /home/jenkins-slave/norman.pem logs@logs.openstack.tld "chmod a+rx -R /srv/logs/$ZUUL_CHANGE/$ZUUL_PATCHSET/"

set -e
