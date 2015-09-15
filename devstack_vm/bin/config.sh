# Configuration setup
#
# Devstack
#
DEVSTACK_LOGS="/opt/stack/logs/screen"
DEVSTACK_LOG_DIR="/opt/stack/logs"
DEVSTACK_DIR="/home/ubuntu/devstack"
LOCALRC="/home/ubuntu/devstack/localrc"
LOCALCONF="/home/ubuntu/devstack/local.conf"
PBR_LOC="/opt/stack/pbr"

HYPERV_LOGS="/openstack/logs"
TEMPEST_LOGS="/home/ubuntu/tempest"
HYPERV_CONFIGS="/openstack/config"

LOG_DST="/home/ubuntu/aggregate"
LOG_DST_DEVSTACK="$LOG_DST/devstack_logs"
LOG_DST_HV="$LOG_DST/Hyper-V_logs"
CONFIG_DST_DEVSTACK="$LOG_DST/devstack_config"
CONFIG_DST_HV="$LOG_DST/Hyper-V_config"

BUILDDIR="/opt/stack"
