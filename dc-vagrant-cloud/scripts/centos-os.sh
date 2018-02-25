#!/bin/bash
#  centos openstack with packstack provision script for packer  
#  Robert Wang
#  Feb 25th, 2018

set -x

# step0 presetup
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

# step 1 sw repo
yum install -y centos-release-openstack-pike
yum install -y openstack-utils
yum update -y

# step 2 install packstack
yum install -y openstack-packstack

# step3 run packstack
packstack --gen-answer-file=packstack_`date +"%Y-%m-%d"`.conf
cp packstack_`date +"%Y-%m-%d"`.conf latest_packstack.conf

natif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -1`
natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

osif=$natif
osip=$natip

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

# update /etc/hosts

sed -i  "/localhost/d" /etc/hosts
sed -i  "/127.0.0.1/d" /etc/hosts
sed -i  "/$osip/d" /etc/hosts

echo "127.0.0.1    lo localhost" | sudo tee -a /etc/hosts
echo "$osip    "`hostname` |sudo tee -a /etc/hosts

$CONFIGSET CONFIG_CONTROLLER_HOST $osip
$CONFIGSET CONFIG_COMPUTE_HOSTS $osip
$CONFIGSET CONFIG_NETWORK_HOSTS $osip
$CONFIGSET CONFIG_STORAGE_HOST $osip
$CONFIGSET CONFIG_SAHARA_HOST $osip
$CONFIGSET CONFIG_AMQP_HOST $osip
$CONFIGSET CONFIG_MARIADB_HOST $osip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$osip
$CONFIGSET CONFIG_REDIS_HOST $osip

$CONFIGSET CONFIG_DEFAULT_PASSWORD demo
$CONFIGSET CONFIG_KEYSTONE_ADMIN_PW demo
$CONFIGSET CONFIG_PROVISION_DEMO n
$CONFIGSET CONFIG_CINDER_INSTALL n
$CONFIGSET CONFIG_SWIFT_INSTALL n
$CONFIGSET CONFIG_CEILOMETER_INSTALL n
$CONFIGSET CONFIG_NAGIOS_INSTALL n

$CONFIGSET CONFIG_NOVA_COMPUTE_PRIVIF lo
$CONFIGSET CONFIG_NOVA_NETWORK_PRIVIF lo

$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$osif

packstack --answer-file latest_packstack.conf  || echo "packstack exited $? and is suppressed."

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_admin

rm /home/vagrant/keystonerc_admin
cp /root/keystonerc_admin /home/vagrant/
chown vagrant:vagrant /home/vagrant/keystonerc*






