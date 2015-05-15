#!/bin/bash

WORK_DIR=`dirname $0`
source $HOME/octavian/data/run_params.txt
CONSOLE_LOG="$HOME/octavian/data/console-$NAME.log"
LOGS_ROOT="$HOME/octavian/data/"

#Import library functions
source $WORK_DIR/../devstack_vm/bin/library.sh
source $HOME/octavian/data/creds.txt

PROJECT="openstack/nova"

while [ $# -gt 0 ];
do
    case $1 in
        --build-for)
            PROJECT=$2
            shift;;
    esac
    shift
done

PROJECT_NAME=$(basename $PROJECT)

tempest_dir="/opt/stack/tempest"
run_ssh_cmd ubuntu@$FLOATING_IP /home/jenkins-slave/admin-msft.pem "mkdir -p $tempest_dir" >> $CONSOLE_LOG 2>&1
run_ssh_cmd ubuntu@$FLOATING_IP /home/jenkins-slave/admin-msft.pem "source /home/ubuntu/keystonerc; /home/ubuntu/bin/run_tests.sh $tempest_dir" >> $CONSOLE_LOG 2>&1
LOGS_FOLDER=$LOGS_ROOT`date +%Y-%m-%d-%H%M%S`
mkdir $LOGS_FOLDER
scp -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/home/ubuntu/bin/results.html $LOGS_FOLDER
scp -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/home/ubuntu/bin/subunit-output.log $LOGS_FOLDER
scp -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/opt/stack/logs/stack.sh.txt $LOGS_FOLDER
scp -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i /home/jenkins-slave/admin-msft.pem ubuntu@$FLOATING_IP:/opt/stack/logs/screen/* $LOGS_FOLDER
scp -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i /home/jenkins-slave/admin-msft.pem -r ubuntu@$FLOATING_IP:/openstack/logs/* $LOGS_FOLDER
rm -rf $LOGS_FOLDER/*`date +%Y-%m`*
