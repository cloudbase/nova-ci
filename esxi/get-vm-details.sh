set -e

vm_hostname=$1

VMID=$(vim-cmd vmsvc/getallvms | grep -i $vm_hostname)

vim-cmd vmsvc/get.guest $VMID
