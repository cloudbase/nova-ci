#!/bin/bash
set -e

source /home/ubuntu/devstack/functions
source /home/ubuntu/devstack/functions-common

echo "Before updating nova flavors:"
nova flavor-list

nova flavor-delete 42
nova flavor-create m1.nano 42 128 1 1

nova flavor-delete 84
nova flavor-create m1.micro 84 128 2 1

nova flavor-delete 451
nova flavor-create m1.heat 451 512 5 1

echo "After updating nova flavors:"
nova flavor-list

# Add DNS config to the private network
subnet_id=`neutron subnet-show private-subnet | grep ' id ' | awk '{print $4}'`
neutron subnet-update $subnet_id --dns_nameservers list=true 8.8.8.8 8.8.4.4

echo "Neutron networks:"
neutron net-list
for net in `neutron net-list | grep -v '\-\-' | grep -v "subnets" | awk {'print $2'}`; do neutron net-show $net; done
echo "Neutron subnetworks:"
neutron subnet-list
for subnet in `neutron subnet-list -F name | grep -v '\-\-' | grep -v "name" | awk {'print $2'}`; do neutron subnet-show $subnet; done

TEMPEST_CONFIG=/opt/stack/tempest/etc/tempest.conf

iniset $TEMPEST_CONFIG compute volume_device_name "sdb"
iniset $TEMPEST_CONFIG compute min_compute_nodes 2
iniset $TEMPEST_CONFIG compute-feature-enabled rdp_console true
iniset $TEMPEST_CONFIG compute-feature-enabled block_migrate_cinder_iscsi True
iniset $TEMPEST_CONFIG compute-feature-enabled block_migration_for_live_migration True
iniset $TEMPEST_CONFIG compute-feature-enabled live_migration True
iniset $TEMPEST_CONFIG compute-feature-enabled interface_attach False

iniset $TEMPEST_CONFIG scenario img_dir "/home/ubuntu/devstack/files/images/"
iniset $TEMPEST_CONFIG scenario img_file "cirros-0.3.4-x86_64.vhdx"
iniset $TEMPEST_CONFIG scenario img_disk_format vhd

IMAGE_REF=`iniget $TEMPEST_CONFIG compute image_ref`
iniset $TEMPEST_CONFIG compute image_ref_alt $IMAGE_REF

iniset $TEMPEST_CONFIG compute build_timeout 360
iniset $TEMPEST_CONFIG orchestration build_timeout 360
iniset $TEMPEST_CONFIG volume build_timeout 360
iniset $TEMPEST_CONFIG boto build_timeout 360

iniset $TEMPEST_CONFIG compute ssh_timeout 360
iniset $TEMPEST_CONFIG compute allow_tenant_isolation True
