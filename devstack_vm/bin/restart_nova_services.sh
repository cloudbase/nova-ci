#!/bin/bash
source /home/ubuntu/keystonerc
TOP_DIR=/home/ubuntu/devstack
source $TOP_DIR/functions
source $TOP_DIR/inc/meta-config
source $TOP_DIR/lib/stack
source $TOP_DIR/stackrc
source $TOP_DIR/lib/database
source $TOP_DIR/lib/rpc_backend
source $TOP_DIR/lib/apache
source $TOP_DIR/lib/tls
source $TOP_DIR/lib/infra
source $TOP_DIR/lib/keystone
source $TOP_DIR/lib/nova
stop_nova_rest
start_nova_api
start_nova_rest
