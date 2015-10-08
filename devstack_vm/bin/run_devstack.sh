#!/bin/bash
. /home/ubuntu/bin/utils.sh
set -x
set -e
#sudo ifconfig eth0 promisc up
sudo ifconfig eth1 promisc up

HOSTNAME=$(hostname)

sudo sed -i '2i127.0.0.1  '$HOSTNAME'' /etc/hosts

# Add pip cache for devstack
mkdir -p $HOME/.pip
echo "[global]" > $HOME/.pip/pip.conf
echo "trusted-host = dl.openstack.tld" >> $HOME/.pip/pip.conf
echo "index-url = http://dl.openstack.tld:8080/root/pypi/+simple/" >> $HOME/.pip/pip.conf
echo "[install]" >> $HOME/.pip/pip.conf
echo "trusted-host = dl.openstack.tld" >> $HOME/.pip/pip.conf
echo "find-links =" >> $HOME/.pip/pip.conf
echo "    http://dl.openstack.tld/wheels" >> $HOME/.pip/pip.conf

sudo mkdir -p /root/.pip
sudo cp $HOME/.pip/pip.conf /root/.pip/
sudo chown -R root:root /root/.pip

# Update pip to latest
sudo easy_install -U pip

# Update six to latest version
sudo pip install -U six
sudo pip install -U kombu

DEVSTACK_LOGS="/opt/stack/logs/screen"
LOCALRC="/home/ubuntu/devstack/localrc"
LOCALCONF="/home/ubuntu/devstack/local.conf"
PBR_LOC="/opt/stack/pbr"
# Clean devstack logs
sudo rm -f "$DEVSTACK_LOGS/*"
sudo rm -rf "$PBR_LOC"

MYIP=$(/sbin/ifconfig eth0 2>/dev/null| grep "inet addr:" 2>/dev/null| sed 's/.*inet addr://g;s/ .*//g' 2>/dev/null)

if [ -e "$LOCALCONF" ]
then
    	[ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALCONF"
fi

if [ -e "$LOCALRC" ]
then
    	[ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALRC"
fi

cd /home/ubuntu/devstack
git pull

./unstack.sh

if [ -d "/home/ubuntu/.cache/pip/wheels" ]
then
        sudo chown -R ubuntu.ubuntu /home/ubuntu/.cache/pip/wheels
else
        echo "Folder /home/ubuntu/.cache/pip/wheels not found!"
fi

# stack.sh output log
STACK_LOG="/opt/stack/logs/stack.sh.txt"
# keep this many rotated stack.sh logs
STACK_ROTATE_LIMIT=5
rotate_log $STACK_LOG $STACK_ROTATE_LIMIT

sed -i "s#PIP_GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py#PIP_GET_PIP_URL=http://dl.openstack.tld/get-pip.py#g" /home/ubuntu/devstack/tools/install_pip.sh

# 8 Oct 2015 # workaround for https://bugs.launchpad.net/nova/+bug/1503974
set +e
pushd /opt/stack/nova
git config --global user.name "hyper-v-ci"
git config --global user.email "microsoft_hyper-v_ci@microsoft.com"
git fetch https://review.openstack.org/openstack/nova refs/changes/67/232367/4 && git cherry-pick FETCH_HEAD || echo "Could be that patch/set changed or it was merged in master!"
popd
set -e

#set -o pipefail
#./stack.sh 2>&1 | tee /opt/stack/logs/stack.sh.txt
nohup ./stack.sh > $STACK_LOG 2>&1 &
pid=$!
wait $pid
cat $STACK_LOG

echo "Cleaning caches before starting tests; needed to avoid memory starvation"
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
