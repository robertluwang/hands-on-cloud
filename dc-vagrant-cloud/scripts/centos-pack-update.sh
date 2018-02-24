#!/bin/bash
# centos-pack-update.sh
# centos base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 24th, 2018

set -x

yum install -y openvswitch
systemctl start openvswitch

# check how many interface
nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2`
numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2|wc -l`

# if only one NIC is NAT; if two NICs then pick up 2nd NIC - private network 

if [ $numif = 2 ]
then
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ $natip = '' ];then
        natip=`cat /etc/sysconfig/network-scripts/ifcfg-br-ex|grep IPADDR=|cut -d= -f2`
    fi
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    osif=$hoif
    osip=$hoip
else
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ $natip = '' ];then
        natip=`cat /etc/sysconfig/network-scripts/ifcfg-br-ex|grep IPADDR=|cut -d= -f2`
    fi
    osif=$natif
    osip=$natip

    ipconf=`cat latest_packstack.conf |grep CONFIG_CONTROLLER_HOST=|cut -d= -f2`

    if [ $natip = $ipconf ] && [ -f /etc/sysconfig/network-scripts/ifcfg-br-ex ]
    then
        exit 0 
    fi
fi

ovsif=$natif
ovsip=$natip

# update /etc/hosts

sed -i  '/localhost/d' /etc/hosts
sed -i  '/$osip/d' /etc/hosts

echo "127.0.0.1    lo localhost" | sudo tee -a /etc/hosts
echo "$osip    "`hostname` |sudo tee -a /etc/hosts

# update latest_packstack.conf

sed -i "/^CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$osip" latest_packstack.conf
sed -i "/^CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$osip" latest_packstack.conf
sed -i "/^CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$osip" latest_packstack.conf
sed -i "/^CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=ldap://$osip" latest_packstack.conf
sed -i "/^CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$osip" latest_packstack.conf

sed -i "/^CONFIG_NEUTRON_OVS_BRIDGE_IFACES=/c CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:$ovsif" latest_packstack.conf

sed -i "s/$ipconf/$osip/g" latest_packstack.conf 

echo "CONFIG_NOVA_COMPUTE_PRIVIF=lo" | sudo tee -a latest_packstack.conf
echo "CONFIG_NOVA_NETWORK_PRIVIF=lo" | sudo tee -a latest_packstack.conf

packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."

# update source file

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_admin
#sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_demo

rm /home/vagrant/keystonerc_admin
#rm /home/vagrant/keystonerc_demo
cp /root/keystonerc_admin /home/vagrant/
#cp /root/keystonerc_demo /home/vagrant/
chown vagrant:vagrant /home/vagrant/keystonerc*

# ovs config 

cp /etc/sysconfig/network-scripts/ifcfg-$ovsif /etc/sysconfig/network-scripts/ifcfg-br-ex

# generate new interface file
cat <<EOF > /tmp/ifcfg-$ovsif
DEVICE=$ovsif
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
EOF

mv /tmp/ifcfg-$ovsif /etc/sysconfig/network-scripts

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
IPADDR=$ovsip
NETMASK=255.255.255.0
GATEWAY=$os_gw
DNS1=$os_dns
DNS2=8.8.8.8
EOF

mv /tmp/ifcfg-br-ex /etc/sysconfig/network-scripts

cat /etc/hosts|grep "127.0.0.1    lo localhost" > /tmp/hosts.txt
cat /etc/hosts|grep $osip >> /tmp/hosts.txt

cp /tmp/hosts.txt /etc/hosts

# make ovs br-ex change
systemctl restart network.service




