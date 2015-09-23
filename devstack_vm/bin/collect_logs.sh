#!/bin/bash

. /home/ubuntu/bin/config.sh

TAR=$(which tar)
GZIP=$(which gzip)

function emit_error() {
    echo "ERROR: $1"
    exit 1
}

function emit_warning() {
    echo "WARNING: $1"
    return 0
}

function archive_devstack_logs() {
    if [ ! -d "$LOG_DST_DEVSTACK" ]
    then
        mkdir -p "$LOG_DST_DEVSTACK" || emit_error "L30: Failed to create $LOG_DST_DEVSTACK"
    fi

    for i in `ls -A $DEVSTACK_LOGS`
    do
        if [ -h "$DEVSTACK_LOGS/$i" ]
        then
                REAL=$(readlink "$DEVSTACK_LOGS/$i")
                $GZIP -c "$REAL" > "$LOG_DST_DEVSTACK/$i.gz" || emit_warning "L38: Failed to archive devstack logs"
        fi
    done
    $GZIP -c /var/log/mysql/error.log > "$LOG_DST_DEVSTACK/mysql_error.log.gz"
    $GZIP -c /var/log/cloud-init.log > "$LOG_DST_DEVSTACK/cloud-init.log.gz"
    $GZIP -c /var/log/cloud-init-output.log > "$LOG_DST_DEVSTACK/cloud-init-output.log.gz"
    $GZIP -c /var/log/dmesg > "$LOG_DST_DEVSTACK/dmesg.log.gz"
    $GZIP -c /var/log/kern.log > "$LOG_DST_DEVSTACK/kern.log.gz"
    $GZIP -c /var/log/syslog > "$LOG_DST_DEVSTACK/syslog.log.gz"
    $GZIP -c /opt/stack/logs/stack.sh.txt > "$LOG_DST_DEVSTACK/stack.sh.txt.gz"
    mkdir -p "$LOG_DST_DEVSTACK/rabbitmq"
    cp /var/log/rabbitmq/* "$LOG_DST_DEVSTACK/rabbitmq"
    sudo rabbitmqctl status > "$LOG_DST_DEVSTACK/rabbitmq/status.txt" 2>&1
    $GZIP $LOG_DST_DEVSTACK/rabbitmq/*
    mkdir -p "$LOG_DST_DEVSTACK/openvswitch"
    cp /var/log/openvswitch/* "$LOG_DST_DEVSTACK/openvswitch"
    $GZIP $LOG_DST_DEVSTACK/openvswitch/*
}

function archive_devstack_configs() {

    for i in ceilometer cinder glance keystone neutron nova swift openvswitch
    do
        mkdir -p $CONFIG_DST_DEVSTACK/$i || emit_error "L30: Failed to create $CONFIG_DST_DEVSTACK/$i"
        for j in `ls -A /etc/$i`
        do
            if [ -d /etc/$i/$j ]
            then
                $TAR cvzf "$CONFIG_DST_DEVSTACK/$i/$j.tar.gz" "/etc/$i/$j"
            else
                $GZIP -c "/etc/$i/$j" > "$CONFIG_DST_DEVSTACK/$i/$j.gz" || emit_warning "L38: Failed to archive devstack configs"
            fi
        done
    done
    $GZIP -c /home/ubuntu/devstack/local.conf > "$CONFIG_DST_DEVSTACK/local.conf.gz"
    $GZIP -c /opt/stack/tempest/etc/tempest.conf > "$CONFIG_DST_DEVSTACK/tempest.conf.gz"
    df -h > "$CONFIG_DST_DEVSTACK/df.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/df.txt"
    cp /home/ubuntu/bin/excluded-tests.txt "$CONFIG_DST_DEVSTACK/excluded-tests.txt"
    cp /home/ubuntu/bin/isolated-tests.txt "$CONFIG_DST_DEVSTACK/isolated-tests.txt"
    iptables-save > "$CONFIG_DST_DEVSTACK/iptables.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/iptables.txt"
    dpkg-query -l > "$CONFIG_DST_DEVSTACK/dpkg-l.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/dpkg-l.txt"
    pip freeze > "$CONFIG_DST_DEVSTACK/pip-freeze.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/pip-freeze.txt"
    ps axwu > "$CONFIG_DST_DEVSTACK/pidstat.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/pidstat.txt"
    ifconfig -a -v > "$CONFIG_DST_DEVSTACK/ifconfig.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/ifconfig.txt"
    sudo ovs-vsctl -v show > "$CONFIG_DST_DEVSTACK/ovs_bridges.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/ovs_bridges.txt"
}

function archive_hyperv_configs() {
    if [ ! -d "$CONFIG_DST_HV" ]
    then
        mkdir -p "$CONFIG_DST_HV"
    fi
    COUNT=1
    for i in `ls -A "$HYPERV_CONFIGS"`
    do
        if [ -d "$HYPERV_CONFIGS/$i" ]
        then
            NAME=`echo $i | sed 's/^\(hv-compute[0-9]\{2,3\}\)\|^\(c[0-9]-r[0-9]-u[0-9]\{2\}\)/hv-compute'$COUNT'/g'`
            
            mkdir -p "$CONFIG_DST_HV/$NAME"
            COUNT=$(($COUNT + 1))

            for j in `ls -A "$HYPERV_CONFIGS/$i"`
            do
                if [ -d "$HYPERV_CONFIGS/$i/$j" ]
                then
                    mkdir -p "$CONFIG_DST_HV/$NAME/$j"
                    for k in `ls -A "$HYPERV_CONFIGS/$i/$j"`
                    do
                        if [ -d "$HYPERV_CONFIGS/$i/$j/$k" ]
                        then
                            $TAR cvzf "$CONFIG_DST_HV/$NAME/$j/$k.tar.gz" "$HYPERV_CONFIGS/$i/$j/$k"
                        else
                            $GZIP -c "$HYPERV_CONFIGS/$i/$j/$k" > "$CONFIG_DST_HV/$NAME/$j/$k.gz" || emit_warning "L93: Failed to archive $HYPERV_CONFIGS/$i/$j/$k"
                        fi
                    done
                else
                    $GZIP -c "$HYPERV_CONFIGS/$i/$j" > "$CONFIG_DST_HV/$NAME/$j.gz" || emit_warning "L97: Failed to archive $HYPERV_CONFIGS/$i/$j"
                fi
            done
        else
            $GZIP -c "$HYPERV_CONFIGS/$i" > "$CONFIG_DST_HV/$i.gz" || emit_warning "L101: Failed to archive $HYPERV_CONFIGS/$i"
        fi
    done
}

function archive_hyperv_logs() {
    if [ ! -d "$LOG_DST_HV" ]
    then
        mkdir -p "$LOG_DST_HV"
    fi
    COUNT=1
    for i in `ls -A "$HYPERV_LOGS"`
    do
        if [ -d "$HYPERV_LOGS/$i" ]
        then
            NAME=`echo $i | sed 's/^\(hv-compute[0-9]\{2,3\}\)\|^\(c[0-9]-r[0-9]-u[0-9]\{2\}\)/hv-compute'$COUNT'/g'`
            
            mkdir -p "$LOG_DST_HV/$NAME"
            COUNT=$(($COUNT + 1))

            for j in `ls -A "$HYPERV_LOGS/$i"`;
            do
                $GZIP -c "$HYPERV_LOGS/$i/$j" > "$LOG_DST_HV/$NAME/$j.gz" || emit_warning "L123: Failed to archive $HYPERV_LOGS/$i/$j"
            done
        else
            $GZIP -c "$HYPERV_LOGS/$i" > "$LOG_DST_HV/$i.gz" || emit_warning "L126: Failed to archive $HYPERV_LOGS/$i"
        fi
    done
}
function archive_tempest_files() {
    for i in `ls -A $TEMPEST_LOGS`
    do
        $GZIP "$TEMPEST_LOGS/$i" -c > "$LOG_DST/$i.gz" || emit_error "L133: Failed to archive tempest logs"
    done
}

# Clean
[ -d "$LOG_DST" ] && rm -rf "$LOG_DST"
mkdir -p "$LOG_DST"

archive_devstack_logs
archive_devstack_configs
archive_hyperv_configs
archive_hyperv_logs
archive_tempest_files

pushd "$LOG_DST"
$TAR -czf "$LOG_DST.tar.gz" . || emit_error "L147: Failed to archive aggregate logs"
popd

exit 0
