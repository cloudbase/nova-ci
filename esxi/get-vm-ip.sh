set -e

vm_hostname=$1

#vim-cmd vmsvc/getallvms | grep -i $vm_hostname | xargs vim-cmd vmsvc/get.guest | grep ipAddress | sed -n 1p | cut -d '"' -f 2 | cut -d '<' -f 2 | awk -F\> '{ print $1 }'

VMID=$(vim-cmd vmsvc/getallvms | grep -i $vm_hostname)

vim-cmd vmsvc/get.guest $VMID | grep ipAddress | sed -n 1p | cut -d '"' -f 2 | cut -d '<' -f 2 | awk -F\> '{ print $1 }'
