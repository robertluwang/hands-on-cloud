#!/bin/bash
# centos-pack-update.sh
# centos base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 24th, 2018

set -x

yum install -y openvswitch
systemctl start openvswitch

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

# check how many interface
nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2`
numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2|wc -l`

# if only one NIC is NAT; if two NICs then pick up 2nd Hostonly as openstack network 

ipconf=`$CONFIGGET CONFIG_CONTROLLER_HOST`

if [ $numif = 2 ]
then
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ "$natip" = "" ];then
        natip=`ip addr show br-ex|grep "global dynamic br-ex"|awk '{print $2}'|cut -d/ -f1`
    fi
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    osif=$hoif
    osip=$hoip
else
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ "$natip" = "" ];then
        natip=`ip addr show br-ex|grep "global dynamic br-ex"|awk '{print $2}'|cut -d/ -f1`
    fi

    curl -LO https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/scripts/centos-ovs-fix.sh
    chmod +x centos-ovs-fix.sh
    ./centos-ovs-fix.sh eth0 $natip
    exit 0 
fi

ovsif=$natif
ovsip=$natip

# update /etc/hosts

sed -i  "/localhost/d" /etc/hosts
sed -i  "/127.0.0.1/d" /etc/hosts
sed -i  "/$natip/d" /etc/hosts
sed -i  "/$osip/d" /etc/hosts

echo "127.0.0.1    lo localhost" | sudo tee -a /etc/hosts
echo "$osip    "`hostname` |sudo tee -a /etc/hosts

# update latest_packstack.conf

$CONFIGSET CONFIG_CONTROLLER_HOST $osip
$CONFIGSET CONFIG_COMPUTE_HOSTS $osip
$CONFIGSET CONFIG_NETWORK_HOSTS $osip
$CONFIGSET CONFIG_STORAGE_HOST $osip
$CONFIGSET CONFIG_SAHARA_HOST $osip
$CONFIGSET CONFIG_AMQP_HOST $osip
$CONFIGSET CONFIG_MARIADB_HOST $osip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$osip
$CONFIGSET CONFIG_REDIS_HOST $osip

$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$ovsif

# update source file

packstack --answer-file latest_packstack.conf --timeout=1800 || echo "packstack exited $? and is suppressed."

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_*
sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /home/vagrant/keystonerc_*
cp /root/keystonerc_* /home/vagrant
chown vagrant:vagrant /home/vagrant/keystonerc*

