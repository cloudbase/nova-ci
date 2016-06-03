#!/bin/bash

hyperv01=$1
hyperv02=$2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/config.sh
. $DIR/utils.sh

set -x
set -e
#sudo ifconfig eth0 promisc up
sudo ifconfig eth1 promisc up
sudo dhclient -v eth1

HOSTNAME=$(hostname)

sudo sed -i '2i127.0.0.1  '$HOSTNAME'' /etc/hosts

firewall_manage_ports "" add disable ${TCP_PORTS[@]}

# Add pip cache for devstack
mkdir -p $HOME/.pip
echo "[global]" > $HOME/.pip/pip.conf
echo "trusted-host = 10.0.110.1" >> $HOME/.pip/pip.conf
echo "index-url = http://10.0.110.1:8080/cloudbase/CI/+simple/" >> $HOME/.pip/pip.conf
echo "[install]" >> $HOME/.pip/pip.conf
echo "trusted-host = 10.0.110.1" >> $HOME/.pip/pip.conf

sudo mkdir -p /root/.pip
sudo cp $HOME/.pip/pip.conf /root/.pip/
sudo chown -R root:root /root/.pip

# Update packages to latest version
sudo easy_install -U pip
sudo pip install -U six
sudo pip install -U kombu
sudo pip install -U pbr

# Clean devstack logs
sudo rm -f "$DEVSTACK_LOGS/*"
sudo rm -rf "$PBR_LOC"
sudo sed -i  "$ a search openstack.tld" /etc/resolv.conf

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

screen_pid=$(ps auxw | grep -i screen | grep -v grep | awk '{print $2}')
if [[ -n $screen_pid ]]; then
    kill -9 $screen_pid
fi

if `screen -ls | grep "Dead"`; then
    screen -wipe
fi

if [ -d "/home/ubuntu/.cache/pip/wheels" ]
then
        sudo chown -R ubuntu.ubuntu /home/ubuntu/.cache/pip/wheels
else
        echo "Folder /home/ubuntu/.cache/pip/wheels not found!"
fi

rotate_log $STACK_LOG $STACK_ROTATE_LIMIT

sed -i "s#PIP_GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py#PIP_GET_PIP_URL=http://10.0.110.1/get-pip.py#g" /home/ubuntu/devstack/tools/install_pip.sh

#Requested by Claudiu Belu, temporary hack:
sudo pip install -U /opt/stack/networking-hyperv

nohup ./stack.sh > $STACK_LOG 2>&1 &
pid=$!
wait $pid
cat $STACK_LOG

firewall_manage_ports $hyperv01 add enable ${TCP_PORTS[@]}
firewall_manage_ports $hyperv02 add enable ${TCP_PORTS[@]}

echo "Cleaning caches before starting tests; needed to avoid memory starvation"
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
