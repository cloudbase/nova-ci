#!/bin/bash

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

set +e
# Ensure subunit is available
sudo apt-get install subunit -y -o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true -f
# moreutils is needed for tc (timestamp)
sudo apt-get install moreutils -y -o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true -f
# sysstat needed for iostat
sudo apt-get install sysstat -y -o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true -f
set -e

DEVSTACK_LOGS="/opt/stack/logs/screen"
LOCALRC="/home/ubuntu/devstack/localrc"
LOCALCONF="/home/ubuntu/devstack/local.conf"
PBR_LOC="/opt/stack/pbr"
# Clean devstack logs
rm -f "$DEVSTACK_LOGS/*"
rm -rf "$PBR_LOC"

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

#set -o pipefail
#./stack.sh 2>&1 | tee /opt/stack/logs/stack.sh.txt
nohup ./stack.sh > /opt/stack/logs/stack.sh.txt 2>&1 &
pid=$!
wait $pid
cat /opt/stack/logs/stack.sh.txt

echo "Cleaning caches before starting tests; needed to avoid memory starvation"
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
