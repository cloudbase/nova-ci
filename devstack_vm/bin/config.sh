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

TCP_PORTS=(80 443 3260 3306 5000 5672 6000 6001 6002 8000 8003 8004 8080 8773 8774 8775 8776 8777 9191 9292 9696 35357)

# stack.sh output log
STACK_LOG="/opt/stack/logs/stack.sh.txt"
# keep this many rotated stack.sh logs
STACK_ROTATE_LIMIT=5

tests_dir="/opt/stack/tempest"
parallel_tests=4
max_attempts=3
test_suite="default"
log_file="/home/ubuntu/tempest/subunit-output.log"
results_html_file="/home/ubuntu/tempest/results.html"
tempest_output_file="/home/ubuntu/tempest/tempest-output.log"
subunit_stats_file="/home/ubuntu/tempest/subunit_stats.log"
TEMPEST_DIR="/home/ubuntu/tempest"
TEMPEST_CONFIG="/opt/stack/tempest/etc/tempest.conf"
