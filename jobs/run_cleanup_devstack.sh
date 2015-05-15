source /home/jenkins-slave/keystonerc_admin
source /usr/local/src/nova-ci/jobs/library.sh

set +e

echo "Releasing devstack floating IP"
nova remove-floating-ip "$NAME" "$FLOATING_IP"
echo "Removing devstack VM"
nova delete "$NAME"
/usr/local/src/nova-ci/vlan_allocation.py -r $NAME
echo "Deleting devstack floating IP"
nova floating-ip-delete "$FLOATING_IP"

set -e
