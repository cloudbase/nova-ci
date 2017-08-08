set -e

usage() {
        echo "$0 --project ZUUL_PROJECT --zuul-change ZUUL_CHANGE --zuul-patchset ZUUL_PATCHSET"
}

LIVE_MIGRATION="no"
DEBUG_JOB="no"
while [ $# -gt 0 ];
do
    case $1 in
        --project)
            ZUUL_PROJECT=$2
            shift;;
        --zuul-change)
            ZUUL_CHANGE=$2
            shift;;
        --zuul-patchset)
            ZUUL_PATCHSET=$2
            shift;;
	--debug-job)
	    DEBUG_JOB="yes"
	    ;;
        *)
            PARAM=$1
            echo "unknown parameter $PARAM"
            usage
            exit 1;;
    esac
    shift
done

if [ -z "$ZUUL_PROJECT" ] || [ -z "$ZUUL_CHANGE" ] || [ -z "$ZUUL_PATCHSET" ]
then
        echo "PROJECT ZUUL_CHANGE ZUUL_PATCHSET are mandatory"
        exit 1
fi

if echo "$ZUUL_PROJECT" | grep -q "/" > /dev/null; then
        ZUUL_PROJECT=${ZUUL_PROJECT#*/}
fi

#ZUUL_PROJECT=${ZUUL_PROJECT#*/}
VM_PREFIX="dvs hv1 hv2 win2016"
VM_PATTERN="$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
VSWITCH="switch-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
PORT_GROUP="port-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
DATASTORE_PATH="/vmfs/volumes/datastore1"
if [[ $DEBUG_JOB == "yes" ]]; then
        VM_PATTERN="$VM_PATTERN-dbg"
	VSWITCH="$VSWITCH-dbg"
	PORT_GROUP="$PORT_GROUP-dbg"
fi

unregister_vms() {
    VMID=$(vim-cmd vmsvc/getallvms | grep -e "-$VM_PATTERN" | awk '{ print $1}')
    if [ -n "$VMID" ]; then
        for id in $VMID; do
            echo "Powering Off and unregistering VM with ID $id"
            vim-cmd vmsvc/power.off $id
            vim-cmd vmsvc/unregister $id
        done
    fi 
}

delete_vm_paths() {
    for prefix in $VM_PREFIX; do
        VM_NAME="$prefix-$VM_PATTERN"
        VM_PATH="$DATASTORE_PATH/$VM_NAME"
        if [ $VM_NAME ] && [ -d $VM_PATH ]; then
            echo "Deleting $VM_PATH"
            rm -r $VM_PATH
        else
            echo "VM $VM_NAME name or path is empty"
        fi
    done
}

delete_switch_portgroup() {
    # Check if portgroup exists
    portgroup_exists=$(esxcfg-vswitch -C $PORT_GROUP)
    if [[ $portgroup_exists == 1 ]]; then
        echo "Removing port group $PORT_GROUP"
        esxcli network vswitch standard portgroup remove -p $PORT_GROUP -v $VSWITCH
    else
        echo "PortGroup $PORT_GROUP does not exist"
    fi

    # Check if vswitch exists
    vswitch_exists=$(esxcfg-vswitch -c $VSWITCH)
    if [[ $vswitch_exists == 1 ]]; then
        echo "Removing vswitch $VSWITCH"
        esxcli network vswitch standard remove -v $VSWITCH
    else
        echo "Switch $VSWITCH does not exist"
    fi
}

# Poweroff and unregister VMs
unregister_vms

# Delete clone VM folders
delete_vm_paths

# Delete portgroups and switch associated with the VMs, if they exist.
delete_switch_portgroup

