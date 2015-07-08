#!/bin/bash

set -x
set -e

sudo ifconfig eth1 promisc up
sudo ifconfig eth2 promisc up

source $HOME/bin/config.sh

HOSTNAME=$(hostname)

sudo sed -i '2i127.0.0.1  '$HOSTNAME'' /etc/hosts

#Update six to latest version
sudo pip install -U six
sudo pip install -U kombu

# Clean devstack logs
rm -f "$DEVSTACK_LOGS/*"
rm -rf "$PBR_LOC"

MYIP=$(/sbin/ifconfig eth0 2>/dev/null| grep "inet addr:" 2>/dev/null| sed 's/.*inet addr://g;s/ .*//g' 2>/dev/null)

if [ -e "$LOCALCONF" ]
then
    	[ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALCONF"
        sed -i 's/^local_ip=.*/local_ip='$MYIP'/g' "$LOCALCONF" 
fi

if [ -e "$LOCALRC" ]
then
    	[ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALRC"
fi

# Moving to devstack dir for further operations
cd $DEVSTACK_DIR
git pull
sudo easy_install -U pip
./unstack.sh

nohup ./stack.sh > $DEVSTACK_LOG_DIR/stack.sh.txt 2>&1 &
pid=$!
wait $pid
cat $DEVSTACK_LOG_DIR/stack.sh.txt
