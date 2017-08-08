set -e

usage() {
        echo "$0 --project ZUUL_PROJECT --zuul-change ZUUL_CHANGE --zuul-patchset ZUUL_PATCHSET --enable-migration [no|yes]"
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
        --enable-migration)
            LIVE_MIGRATION="no"
            ;;
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
DEVSTACK_PARENT="devstack-parent"
HYPERV_PARENT="hyperv2016-parent"
WINDOWS_PARENT="win2016-parent"
DEVSTACK_CLONE="dvs-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
HYPERV_1_CLONE="hv1-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
HYPERV_2_CLONE="hv2-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
WINDOWS_CLONE="win2016-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
VSWITCH="switch-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
PORT_GROUP="port-$ZUUL_PROJECT-$ZUUL_CHANGE-$ZUUL_PATCHSET"
DATASTORE_PATH="/vmfs/volumes/datastore1"
if [[ $DEBUG_JOB == "yes" ]]; then
	DEVSTACK_CLONE="$DEVSTACK_CLONE-dbg"
	HYPERV_1_CLONE="$HYPERV_1_CLONE-dbg"
	HYPERV_2_CLONE="$HYPERV_2_CLONE-dbg"
	WINDOWS_CLONE="$WINDOWS_CLONE-dbg"
	VSWITCH="$VSWITCH-dbg"
	PORT_GROUP="$PORT_GROUP-dbg"
fi

create_vswitch_portgroup() {
  #Check if vswitch exists
  vswitch_exists=$(esxcfg-vswitch -c $VSWITCH)
  if [[ $vswitch_exists == 0 ]]; then
    echo "Creating vswitch $VSWITCH"
    esxcli network vswitch standard add -v $VSWITCH
    echo "Setting security options for vswitch $VSWITCH"
    esxcli network vswitch standard policy security set -p true -m true -f true -v $VSWITCH
  else
    echo "Switch $VSWITCH already exists"
  fi
  
  # Check if portgroup exists
  portgroup_exists=$(esxcfg-vswitch -C $PORT_GROUP)
  if [[ $portgroup_exists == 0 ]]; then
    echo "Creating port group $PORT_GROUP"
    esxcli network vswitch standard portgroup add -p $PORT_GROUP -v $VSWITCH
    echo "Setting vlan_id 4095 (allow VM vlan tags) for port group $PORT_GROUP"
    esxcli network vswitch standard portgroup set -p $PORT_GROUP --vlan-id 4095
  else
    echo "PortGroup $PORT_GROUP already exists on switch $VSWITCH"
  fi
}

create_clone_path() {
  PARENT=$1
  CLONE=$2
  PARENT_PATH="$DATASTORE_PATH/$PARENT"
  CLONE_PATH="$DATASTORE_PATH/$CLONE"
  echo "Copying files from parent $PARENT with path $PARENT_PATH to clone $CLONE with path $CLONE_PATH"
  VMFILE=`grep -E "scsi0\:0\.fileName" "$PARENT_PATH"/*.vmx | grep -o "[0-9]\{6,6\}"`
  mkdir "$CLONE_PATH"
  cp "$PARENT_PATH"/*-"$VMFILE".* "$CLONE_PATH"/$CLONE-"$VMFILE".vmdk
  cp "$PARENT_PATH"/*-"$VMFILE"-delta.* "$CLONE_PATH"/$CLONE-"$VMFILE"-delta.vmdk
  cp "$PARENT_PATH"/*.vmx "$CLONE_PATH"/$CLONE.vmx
}

create_clone_vm() {
  PARENT=$1
  CLONE=$2
  PARENT_PATH="$DATASTORE_PATH/$PARENT"
  CLONE_PATH="$DATASTORE_PATH/$CLONE"
  echo "Starting editing clone $CLONE"
  echo "Checking snapshot file naming"
  VMFILE=`grep -E "scsi0\:0\.fileName" "$PARENT_PATH"/*.vmx | grep -o "[0-9]\{6,6\}"`
  if [ -z "$VMFILE" ]
  then
    echo "No $VMFILE found!"
    exit 1
  fi  
    
  echo "Editing .vmx file for the clone"
  #local fullbasepath=$(readlink -f "$INFOLDER")/
  cd "$CLONE_PATH"/
  
  #delete swap file line, will be auto recreated
  sed -i '/sched.swap.derivedName/d' ./*.vmx
  
  #Change display name config value
  sed -i -e '/displayName =/ s/= .*/= "'$CLONE'"/' ./*.vmx \
  
  # Change parent disk path
  local escapedpath=$(echo "$PARENT_PATH/" | sed -e 's/[\/&]/\\&/g')
  sed -i -e '/parentFileNameHint=/ s/="/="'"$escapedpath"'/' ./*-"$VMFILE".vmdk
  
  # Change delta file
  deltaName=""$CLONE"-"$VMFILE"-delta.vmdk"
  sed -i 's/\(VMFSSPARSE \)\(.*\)/\1"'$deltaName'"/' ./*-"$VMFILE".vmdk

  # Change the fileName of the Disk
  fileName=""$CLONE"-"$VMFILE".vmdk"
  sed -i -e '/scsi0:0.fileName =/ s/= .*/= "'$fileName'"/' ./*.vmx
  
  # Change nvram config
  NVRAM=""$CLONE".nvram"
  sed -i -e '/nvram =/ s/= .*/= "'$NVRAM'"/' ./*.vmx
  
  # Forces generation of new MAC + DHCP
  sed -i '/ethernet0.generatedAddress/d' ./*.vmx
  sed -i '/ethernet0.addressType/d' ./*.vmx
  sed -i '/ethernet1.generatedAddress/d' ./*.vmx
  sed -i '/ethernet1.addressType/d' ./*.vmx
  
  # Change PortGroup for the clone
  sed -i -e '/ethernet1.networkName =/ s/= .*/= "'$PORT_GROUP'"/' ./*.vmx
  
  # Forces creation of a fresh UUID for the VM
  sed -i '/uuid.location/d' ./*.vmx
  sed -i '/uuid.bios/d' ./*.vmx

  # delete machine id
  sed -i '/machine.id/d' *.vmx

  # add machine id
  sed -i -e "\$amachine.id=$CLONE" *.vmx
 
  # Register the machine so that it appears in vSphere.
  echo "Registering clone $CLONE into ESXI"
  FULL_PATH="$CLONE_PATH/*.vmx"
  VMID=`vim-cmd solo/registervm $FULL_PATH`

  # Power on the machine.
  echo "Powering on $CLONE"
  vim-cmd vmsvc/power.on $VMID
}

# Create the switch and the portgroup
create_vswitch_portgroup

# Create the clone folders and copy the snapshot and vmx and rename them to the clones name.
create_clone_path $DEVSTACK_PARENT $DEVSTACK_CLONE
create_clone_path $HYPERV_PARENT $HYPERV_1_CLONE

# Create,edit,register and start the new clone
create_clone_vm $DEVSTACK_PARENT $DEVSTACK_CLONE
create_clone_vm $HYPERV_PARENT $HYPERV_1_CLONE

# Second Hyperv server if live migration is enabled
if [ $LIVE_MIGRATION == "yes" ]; then
    echo "Live migration is enabled, creating the second HyperV slave"
    create_clone_path $HYPERV_PARENT $HYPERV_2_CLONE
    create_clone_vm $HYPERV_PARENT $HYPERV_2_CLONE
fi

# For Cinder create a windows 2016 server clone.
if [ $ZUUL_PROJECT == "cinder" ]; then
    echo "This is a Cinder build, creating a Windows Server 2016 slave"
    create_clone_path $WINDOWS_PARENT $WINDOWS_CLONE
    create_clone_vm $WINDOWS_PARENT $WINDOWS_CLONE
fi

