#!/bin/bash
# centos-ovs-fix.sh
# NAT Network openstack ovs fix script
# Robert Wang @github.com/robertluwang
# Feb 28th, 2018
# $1 - NAT Network NIC ip

set -x

# check interface ifcfg-enp0s3
natif1=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -1`
natif2=`cat /etc/sysconfig/network-scripts/ifcfg-br-ex | grep OVSDHCPINTERFACES|cut -d= -f2`

if [ -z "$1" ];then
    osip=10.0.2.15
else 
    osip=$1
fi

# if find enp0s3 in ifcfg-br-ex, assume NAT NIC already config as OVS DHCP then process NAT Network setup; o/w exit

if [ "natif1" = "natif2" ];then
    osif=$natif1
else
    exit 0 
fi

mv /etc/sysconfig/network-scripts/ifcfg-$osif  /etc/sysconfig/network-scripts/ifcfg-$osif.old
mv /etc/sysconfig/network-scripts/ifcfg-br-ex /etc/sysconfig/network-scripts/ifcfg-br-ex.old

# ovs config 

# generate new interface file
cat <<EOF > /tmp/ifcfg-eth0
DEVICE=eth0
NAME=eth0
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
EOF

mv /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts

# generate ifcfg-br-ex
gw=`echo $osip|cut -d. -f1,2,3`.1

cat <<EOF > /tmp/ifcfg-br-ex
ONBOOT="yes"
NETBOOT="yes"
IPADDR=$1
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

$CONFIGSET CONFIG_CONTROLLER_HOST $osip
$CONFIGSET CONFIG_COMPUTE_HOSTS $osip
$CONFIGSET CONFIG_NETWORK_HOSTS $osip
$CONFIGSET CONFIG_STORAGE_HOST $osip
$CONFIGSET CONFIG_SAHARA_HOST $osip
$CONFIGSET CONFIG_AMQP_HOST $osip
$CONFIGSET CONFIG_MARIADB_HOST $osip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$osip
$CONFIGSET CONFIG_REDIS_HOST $osip

$CONFIGSET CONFIG_NOVA_COMPUTE_PRIVIF lo
$CONFIGSET CONFIG_NOVA_NETWORK_PRIVIF lo

$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$osif

sed -i "s/$ipconf/$osip/g" latest_packstack.conf 

# update source file

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_admin

rm /home/vagrant/keystonerc_admin
cp /root/keystonerc_admin /home/vagrant/
chown vagrant:vagrant /home/vagrant/keystonerc*


 





 



