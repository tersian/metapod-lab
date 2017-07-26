#!/bin/bash

# =========== parameters =============
tenant_count=2
tenant_prefix=labtenant
tenant_admin_prefix=labadmin
tenant_user_prefix=labuser
password=password
openstack_ip=10.21.116.4
priv_net_prefix=priv_net
priv_subnet_prefix=sub$priv_net_prefix
router_prefix=labrouter
public_net=1e85d6a7-ee50-400f-8296-146710e52f39
sec_group=allow-all
image_url=http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
# ====================================

function delete_lab(){
	source ./ONX1_admin-openrc.sh
	openstack router remove subnet $router_prefix$1 $priv_subnet_prefix$1
	openstack router unset --external-gateway $router_prefix$1
	openstack router delete $router_prefix$1
	openstack subnet delete $priv_subnet_prefix$1
	openstack network delete $priv_net_prefix$1
	openstack user delete $tenant_user_prefix$1
	openstack user delete $tenant_admin_prefix$1
	openstack security group delete $sec_group$1
	openstack project delete $tenant_prefix$1
	rm /var/root/openstackrc_$tenant_user_prefix$1
	rm /var/root/openstackrc_$tenant_admin_prefix$1
}

#main 
for i in `seq 1 $tenant_count`; do
	delete_lab $i
done
