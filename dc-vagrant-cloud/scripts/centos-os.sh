#!/bin/bash
#  centos openstack with packstack provision script for packer  
#  Robert Wang
#  Feb 11th, 2018

set -x

# step0 presetup
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

# step 1 sw repo
yum install -y centos-release-openstack-pike openstack-utils
yum-config-manager --enable openstack-pike
yum update -y

# step 2 install packstack
yum install -y openstack-packstack

yum install -y openvswitch
systemctl start openvswitch

# step3 run packstack
packstack --gen-answer-file=packstack_`date +"%Y-%m-%d"`.conf
cp packstack_`date +"%Y-%m-%d"`.conf latest_packstack.conf

natif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|head -1`
natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

osif=$natif
osip=$natip

sed -i "/^CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$osip" latest_packstack.conf
sed -i "/^CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$osip" latest_packstack.conf
sed -i "/^CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=ldap://$osip" latest_packstack.conf
sed -i "/^CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_NEUTRON_OVS_TUNNEL_IF=/c CONFIG_NEUTRON_OVS_TUNNEL_IF=$osif" latest_packstack.conf
sed -i "/^CONFIG_NEUTRON_ML2_VNI_RANGES=/c CONFIG_NEUTRON_ML2_VNI_RANGES=1000:2000" latest_packstack.conf

sed -i '/^CONFIG_DEFAULT_PASSWORD=/c CONFIG_DEFAULT_PASSWORD=demo' latest_packstack.conf
sed -i '/^CONFIG_KEYSTONE_ADMIN_PW=/c CONFIG_KEYSTONE_ADMIN_PW=demo' latest_packstack.conf
sed -i '/^CONFIG_KEYSTONE_DEMO_PW=/c CONFIG_KEYSTONE_DEMO_PW=demo' latest_packstack.conf
sed -i '/^CONFIG_SWIFT_INSTALL=/c CONFIG_SWIFT_INSTALL=n' latest_packstack.conf

packstack --answer-file latest_packstack.conf  || echo "packstack exited $? and is suppressed."

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_admin
sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_demo

rm /home/vagrant/keystonerc_admin
rm /home/vagrant/keystonerc_demo
cp /root/keystonerc_admin /home/vagrant/
cp /root/keystonerc_demo /home/vagrant/
chown vagrant:vagrant /home/vagrant/keystonerc*

# ovs config 

cp /etc/sysconfig/network-scripts/ifcfg-$osif /etc/sysconfig/network-scripts/ifcfg-br-ex

# generate new interface file
cat <<EOF > /tmp/ifcfg-$osif
DEVICE=$osif
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
EOF

mv /tmp/ifcfg-$osif /etc/sysconfig/network-scripts

# generate ifcfg-br-ex
os_gw=`route -en|grep UG|awk '{print $2}'`
os_dns=`cat /etc/resolv.conf|grep nameserver|awk '{print $2}'`

cat <<EOF > /tmp/ifcfg-br-ex
DEVICE=br-ex
BOOTPROTO=static
ONBOOT=yes
TYPE=OVSBridge
DEVICETYPE=ovs
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
IPADDR=$osip
NETMASK=255.255.255.0
GATEWAY=$os_gw
DNS1=$os_dns
DNS2=8.8.8.8
EOF

mv /tmp/ifcfg-br-ex /etc/sysconfig/network-scripts

# make ovs br-ex change
systemctl restart network.service
