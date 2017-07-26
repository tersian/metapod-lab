#!/bin/bash

# =========== parameters =============
tenant_count=20
tenant_prefix=labtenant
tenant_admin_prefix=labadmin
tenant_user_prefix=labuser
password=p455word
admin_password=n0p4ssw0rd
openstack_ip=10.21.116.4
priv_net_prefix=priv_net
priv_subnet_prefix=sub$priv_net_prefix
router_prefix=labrouter
public_net=1e85d6a7-ee50-400f-8296-146710e52f39
sec_group=labsecgroup
image_url=http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
# ====================================

function create_tenant(){
        openstack project create  --description "Tenant used by lab user" $tenant_prefix$1
        openstack user create  --password $password $tenant_user_prefix$1
        openstack user create  --password $admin_password $tenant_admin_prefix$1
        openstack role add --user $tenant_user_prefix$1 --project $tenant_prefix$1 _member_
        openstack role add --user $tenant_admin_prefix$1 --project $tenant_prefix$1 admin
        openstack_identity_file=/var/root/openstackrc_$tenant_admin_prefix$1
        echo "writing admin openstackrc"
        echo -n > $openstack_identity_file
        cat << EOB > $openstack_identity_file
        export OS_AUTH_URL=https://api-onx1.client.metacloud.net:5000/v2.0
        export OS_IDENTITY_API_VERSION=2
        export OS_TENANT_NAME="$tenant_prefix$1"
        export OS_PROJECT_NAME="$tenant_prefix$1"
        export OS_USERNAME="$tenant_admin_prefix$1"
        export OS_PASSWORD="$admin_password"
        export OS_REGION_NAME="onx"
        export PS1='[\u@\h \W($tenant_admin_prefix$1@$tenant_prefix$1)]\$ '
EOB

openstack_identity_file=/var/root/openstackrc_$tenant_user_prefix$1
echo "writing user openstackrc"
echo -n > $openstack_identity_file
cat << EOB > $openstack_identity_file
export OS_AUTH_URL=https://api-onx1.client.metacloud.net:5000/v2.0
export OS_IDENTITY_API_VERSION=2
export OS_TENANT_NAME="$tenant_prefix$1"
export OS_PROJECT_NAME="$tenant_prefix$1"
export OS_USERNAME="$tenant_user_prefix$1"
export OS_PASSWORD="$password"
export OS_REGION_NAME="onx"
export PS1='[\u@\h \W($tenant_user_prefix$1@$tenant_prefix$1)]\$ '
EOB

}

function create_net_and_sec_groups(){
  unset OS_TENANT_ID
  source ./openstackrc_$tenant_admin_prefix$1
	openstack network create $priv_net_prefix$1
	openstack subnet create $priv_subnet_prefix$1 --network $priv_net_prefix$1  --subnet-range 192.168.$1.0/24
	openstack router create $router_prefix$1
  openstack router set $router_prefix$1 --external-gateway $public_net
	openstack router add subnet $router_prefix$1 $priv_subnet_prefix$1
  openstack security group create --description "Dont do this in production" $sec_group$1
	openstack security group rule create --protocol icmp --ingress $sec_group$1
	openstack security group rule create --protocol icmp --egress $sec_group$1
	openstack security group rule create --protocol tcp --dst-port 1:65535 --ingress $sec_group$1
	openstack security group rule create --protocol tcp --dst-port 1:65535 --egress $sec_group$1
  openstack security group rule create --protocol udp --dst-port 1:65535 --ingress $sec_group$1
  openstack security group rule create --protocol udp --dst-port 1:65535 --egress $sec_group$1

}

function upload_image(){
	glance image-create --name="cirros" --disk-format=qcow2 --container-format=bare --is-public=true --copy-from=$image_url
	glance image-list
}

#main
for i in `seq 1 $tenant_count`; do
  source ./ONX1_admin-openrc.sh
	create_tenant $i
  create_net_and_sec_groups $i
#        upload_image
done
