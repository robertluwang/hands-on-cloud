#!/bin/bash
# centos-ovs-fix.sh
# NAT Network openstack ovs fix script
# Robert Wang @github.com/robertluwang
# Feb 28th, 2018
# $1 - NAT Network NIC interface, such as eth0
# $2 - NAT Network NIC ip address, such as 172.25.250.10

set -x

if [ -z "$1" ] && [ -z "$2" ];then
    exit 0 
else 
    natnetif=$1
    natnetip=$2
fi

# check interface ifcfg-enp0s3
natif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -1`

rm /etc/sysconfig/network-scripts/ifcfg-$natif 
rm /etc/sysconfig/network-scripts/ifcfg-br-ex 

# ovs config 

# generate new interface file
cat <<EOF > /tmp/ifcfg-$natnetif
DEVICE=$natnetif
NAME=$natnetif
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
EOF

mv /tmp/ifcfg-$natnetif /etc/sysconfig/network-scripts

# generate ifcfg-br-ex
gw=`echo $natnetip|cut -d. -f1,2,3`.1

cat <<EOF > /tmp/ifcfg-br-ex
ONBOOT="yes"
NETBOOT="yes"
IPADDR=$natnetip
NETMASK=255.255.255.0
GATEWAY=$gw
DNS1=$gw
DNS2=8.8.8.8
DEVICE=br-ex
NAME=br-ex
DEVICETYPE=ovs
OVSBOOTPROTO="static"
TYPE=OVSBridge
OVS_EXTRA="set bridge br-ex fail_mode=standalone"
EOF

mv /tmp/ifcfg-br-ex /etc/sysconfig/network-scripts

# update /etc/resolv.conf

sed -i '/nameserver/d' /etc/resolv.conf
sed -i "$ a nameserver    $gw" /etc/resolv.conf
sed -i "$ a nameserver    8.8.8.8" /etc/resolv.conf

# update latest_packstack.conf

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

ipconf=`$CONFIGGET CONFIG_CONTROLLER_HOST`

$CONFIGSET CONFIG_CONTROLLER_HOST $natnetip
$CONFIGSET CONFIG_COMPUTE_HOSTS $natnetip
$CONFIGSET CONFIG_NETWORK_HOSTS $natnetip
$CONFIGSET CONFIG_STORAGE_HOST $natnetip
$CONFIGSET CONFIG_SAHARA_HOST $natnetip
$CONFIGSET CONFIG_AMQP_HOST $natnetip
$CONFIGSET CONFIG_MARIADB_HOST $natnetip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$natnetif
$CONFIGSET CONFIG_REDIS_HOST $natnetip

$CONFIGSET CONFIG_NOVA_COMPUTE_PRIVIF lo
$CONFIGSET CONFIG_NOVA_NETWORK_PRIVIF lo

$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$natnetif

sed -i "s/$ipconf/$natnetip/g" latest_packstack.conf 

# update source file

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$natnetip:5000/v3" /root/keystonerc_admin

rm /home/vagrant/keystonerc_admin
cp /root/keystonerc_admin /home/vagrant/
chown vagrant:vagrant /home/vagrant/keystonerc*

packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."

