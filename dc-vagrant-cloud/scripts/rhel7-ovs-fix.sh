#!/bin/bash
# rhel7-ovs-fix.sh
# NAT Network openstack ovs fix script
# Robert Wang @github.com/robertluwang
# Sept 24th, 2018
# $1 - NAT Network NIC interface, such as enp0s3
# $2 - NAT Network NIC ip address, such as 188.28.88.10
# $3 - compute1 ip such as 188.28.88.12
# $4 - sudo user, default vagrant

set -x

if [ -z "$1" ] && [ -z "$2" ];then
    exit 0 
else 
    natnetif=$1
    natnetip=$2

    if [ -z "$4" ];then
        sduser="vagrant"
    else
        sduser=$4
    fi
fi

# check interface ifcfg-xxx
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

cp /tmp/ifcfg-$natnetif /etc/sysconfig/network-scripts

# generate ifcfg-br-ex
gw=`echo $natnetip|cut -d. -f1,2,3`.1
net=`echo $natnetip|cut -d. -f1,2,3`.0

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

cp /tmp/ifcfg-br-ex /etc/sysconfig/network-scripts

# update /etc/resolv.conf

sed -i '/nameserver/d' /etc/resolv.conf
sed -i "$ a nameserver    $gw" /etc/resolv.conf
sed -i "$ a nameserver    8.8.8.8" /etc/resolv.conf

# update latest_packstack.conf

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

ipconf=`$CONFIGGET CONFIG_CONTROLLER_HOST`

$CONFIGSET CONFIG_CONTROLLER_HOST $natnetip

if [ -z "$3" ] ;then
    $CONFIGSET CONFIG_COMPUTE_HOSTS $natnetip   
else 
    $CONFIGSET CONFIG_COMPUTE_HOSTS $natnetip,$3
    echo "$3    compute1" |sudo tee -a /etc/hosts
fi

$CONFIGSET CONFIG_NETWORK_HOSTS $natnetip
$CONFIGSET CONFIG_STORAGE_HOST $natnetip
$CONFIGSET CONFIG_SAHARA_HOST $natnetip
$CONFIGSET CONFIG_AMQP_HOST $natnetip
$CONFIGSET CONFIG_MARIADB_HOST $natnetip
$CONFIGSET CONFIG_MONGODB_HOST $natnetip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$natnetip
$CONFIGSET CONFIG_REDIS_HOST $natnetip

$CONFIGSET CONFIG_DEFAULT_PASSWORD demo
$CONFIGSET CONFIG_KEYSTONE_ADMIN_PW demo
$CONFIGSET CONFIG_HEAT_KS_PW demo
$CONFIGSET CONFIG_PROVISION_DEMO n

$CONFIGSET CONFIG_CINDER_INSTALL y
$CONFIGSET CONFIG_SWIFT_INSTALL y
$CONFIGSET CONFIG_CEILOMETER_INSTALL y
$CONFIGSET CONFIG_PANKO_INSTALL y
$CONFIGSET CONFIG_HEAT_INSTALL y
$CONFIGSET CONFIG_HEAT_CFN_INSTALL n

$CONFIGSET CONFIG_NEUTRON_L3_EXT_BRIDGE 
$CONFIGSET CONFIG_NEUTRON_ML2_TYPE_DRIVERS flat,vxlan
$CONFIGSET CONFIG_NEUTRON_ML2_VXLAN_GROUP 239.1.1.2
$CONFIGSET CONFIG_NEUTRON_ML2_VNI_RANGES 1:1000
$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS physnet1:br-ex
$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$natnetif

# SSL 

$CONFIGSET CONFIG_SSL_CACERT_SELFSIGN y
$CONFIGSET CONFIG_AMQP_ENABLE_SSL y

$CONFIGSET CONFIG_SSL_CACERT_FILE /etc/pki/tls/certs/localhost.crt
$CONFIGSET CONFIG_SSL_CACERT_KEY_FILE /etc/pki/tls/private/localhost.key 
$CONFIGSET CONFIG_SSL_CERT_DIR /root/packstackca

sed -i "s/$ipconf/$natnetip/g" latest_packstack.conf 

# update source file

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$natnetip:5000/v3" /root/keystonerc_*
sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$natnetip:5000/v3" /home/$sduser/keystonerc_*
sed  -i "s/^[ \t]*//" /root/keystonerc_*
sed  -i "s/^[ \t]*//" /home/vagrant/keystonerc_*
cp /root/keystonerc_* /home/$sduser
chown $sduser:$sduer /home/$sduser/keystonerc*

systemctl restart network

echo 
echo "The ovs reconfig done:"
echo "ifcfg-"$natnetif
echo "ifcfg-br-ex"
echo "/etc/resolv.conf"
echo "latest_packstack.conf"
echo "keystonerc-*"
echo 
echo "next action:"
echo "1 - power off this vm"
echo "2 - create new or use existing NAT Network interface in virtualbox for $net/24, no DHCP"
echo "3 - add port forwarding to $natnetip:"
echo "127.0.0.1:2222 to $natnetip:22"
echo "127.0.0.1:8080 to $natnetip:80"
echo "4 - in vm setting, change adapter setting:"
echo "Attached to: NAT Network, Name: NatNetworkx"
echo "Adapter Type: Paravirtualized Network (virtio-net)" 
echo "Promiscuous Mode: Allow All"
echo "5 - power on vm, ssh to vm to check networking setting as expected"
echo "6 - run packstack to update change:"
echo "sudo packstack --answer-file latest_packstack.conf"
echo
