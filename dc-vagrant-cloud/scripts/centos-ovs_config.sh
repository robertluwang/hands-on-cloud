#!/bin/bash
# centos-ovs_config.sh
# centos base openstack box packstack ovs config script
# Robert Wang @github.com/robertluwang
# Feb 9th, 2018

set -x

yum install -y openvswitch
systemctl start openvswitch

# if ifcfg-br-ex not exist assume open vswitch not setup yet
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-br-ex ]
then
    # check how many interface
    nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2`
    numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2|wc -l`

    # if only one ovs is NAT; if two then ovs pick up 2nd NIC - private network 

    if [ $numif = 2 ];then
        ovsif=`echo $nics|awk '{print $2}'`
        ovsip=`ip addr show $ovsif|grep $ovsif|grep global|awk '{print $2}'|cut -d/ -f1`
    else
        ovsif=`echo $nics|awk '{print $1}'`
        ovsip=`ip addr show $ovsif|grep $ovsif|grep global|awk '{print $2}'|cut -d/ -f1`
    fi

    # move right NIC interface to backup
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
    ovs_gw=`route -en|grep UG|awk '{print $2}'`
    ovs_dns=`cat /etc/resolv.conf|grep nameserver|awk '{print $2}'`

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
GATEWAY=$ovs_gw
DNS1=$ovs_dns
EOF

    mv /tmp/ifcfg-br-ex /etc/sysconfig/network-scripts

    # update pack config file for ovs 

    sed -i "/^#CONFIG_NEUTRON_OVS_TUNNEL_IF=/c CONFIG_NEUTRON_OVS_TUNNEL_IF=$ovsif" latest_packstack.conf   
    sed -i "/^CONFIG_NEUTRON_OVS_TUNNEL_IF=/c CONFIG_NEUTRON_OVS_TUNNEL_IF=$ovsif" latest_packstack.conf

    sed -i "/^#CONFIG_NEUTRON_ML2_VNI_RANGES=/c CONFIG_NEUTRON_ML2_VNI_RANGES=1000:2000" latest_packstack.conf   
    sed -i "/^CONFIG_NEUTRON_ML2_VNI_RANGES=/c CONFIG_NEUTRON_ML2_VNI_RANGES=1000:2000" latest_packstack.conf

    # restart network.service
    #systemctl restart network.service

    ifdown br-ex && ifup br-ex

fi
