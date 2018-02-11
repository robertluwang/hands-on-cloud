#!/bin/bash
# centos-pack-update.sh
# centos base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 5th, 2018

set -x

if [ -f /etc/sysconfig/network-scripts/ifcfg-br-ex ]
then
    # check how many interface
    nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|head -2`
    numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|head -2|wc -l`

    # if only one ovs is NAT; if two then ovs pick up 2nd NIC - private network 

    if [ $numif = 2 ]
    then
        ovsif=`echo $nics|awk '{print $2}'`
        ovsip=`ip addr show $ovsif|grep $ovsif|grep global|awk '{print $2}'|cut -d/ -f1`
        if [ $ovsip = '' ]
        then
            ovsip=`ip addr|grep br-ex|grep global|awk '{print $2}'|cut -d/ -f1`
            ip addr add dev $ovsif $ovsip/24 
        fi
    else
        ovsif=`echo $nics|awk '{print $1}'`
        ovsip=`ip addr show $ovsif|grep $ovsif|grep global|awk '{print $2}'|cut -d/ -f1`
    fi

    # update latest_packstack.conf

    sed -i "/^#CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$ovsip" latest_packstack.conf   
    sed -i "/^CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$ovsip" latest_packstack.conf

    sed -i "/^CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=ldap://$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=ldap://$ovsip" latest_packstack.conf

    sed -i "/^#CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$ovsip" latest_packstack.conf
    sed -i "/^CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$ovsip" latest_packstack.conf

    packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."

fi
