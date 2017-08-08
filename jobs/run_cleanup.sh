basedir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
source $basedir/library.sh

echo "devstack_params file:"
ls -lia /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
echo "devstack params loaded from /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt :"
cat /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt

set +e

if [ "$IS_DEBUG_JOB" != "yes" ]
    then
        run_ssh_cmd_with_retry root@$ESXI_HOST $DEVSTACK_SSH_KEY "/vmfs/volumes/datastore1/cleanup-env.sh --project $ZUUL_PROJECT --zuul-change $ZUUL_CHANGE --zuul-patchset $ZUUL_PATCHSET"

        rm -f /home/jenkins-slave/runs/devstack_params.$ZUUL_UUID.txt
fi

set -e
