#!/bin/sh
# centos-pack-update.sh
# centos base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 7th, 2018

nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2`
numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2|wc -l`

if [ $numif = 2 ];then
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    
    #sed -i "/$natip/s/$natip/$hoip/g" latest_packstack.conf
    sed -i "/CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$hoip" latest_packstack.conf
    sed -i "/CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$hoip" latest_packstack.conf
    sed -i "/CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$hoip" latest_packstack.conf
    sed -i "/CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$hoip" latest_packstack.conf
    sed -i "/CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$hoip" latest_packstack.conf
    sed -i "/CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$hoip" latest_packstack.conf
    sed -i "/CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$hoip" latest_packstack.conf
    sed -i "/CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=$hoip" latest_packstack.conf
    sed -i "/CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$hoip" latest_packstack.conf

    packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."

    cp  /root/keystonerc_admin /home/vagrant
    cp  /root/keystonerc_demo /home/vagrant
    chown vagrant:vagrant /home/vagrant/keystonerc*
else
    # there is only one default NAT NIC, will use as openstack ip
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

    ipconf=`grep CONFIG_CONTROLLER_HOST= latest_packstack.conf|cut -d= -f2`

    if [ $natip = $ipconf ]
    then
        # NAT ip same as ip on conf, just exit
        exit 0
    else
        # NAT ip diff than ip on conf, will replace it 
        sed -i "/CONFIG_CONTROLLER_HOST=/c CONFIG_CONTROLLER_HOST=$natip" latest_packstack.conf
        sed -i "/CONFIG_COMPUTE_HOSTS=/c CONFIG_COMPUTE_HOSTS=$natip" latest_packstack.conf
        sed -i "/CONFIG_NETWORK_HOSTS=/c CONFIG_NETWORK_HOSTS=$natip" latest_packstack.conf
        sed -i "/CONFIG_STORAGE_HOST=/c CONFIG_STORAGE_HOST=$natip" latest_packstack.conf
        sed -i "/CONFIG_SAHARA_HOST=/c CONFIG_SAHARA_HOST=$natip" latest_packstack.conf
        sed -i "/CONFIG_AMQP_HOST=/c CONFIG_AMQP_HOST=$natip" latest_packstack.conf
        sed -i "/CONFIG_MARIADB_HOST=/c CONFIG_MARIADB_HOST=$natip" latest_packstack.conf
        sed -i "/CONFIG_KEYSTONE_LDAP_URL=/c CONFIG_KEYSTONE_LDAP_URL=$natip" latest_packstack.conf
        sed -i "/CONFIG_REDIS_HOST=/c CONFIG_REDIS_HOST=$natip" latest_packstack.conf

        packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."

        cp  /root/keystonerc_admin /home/vagrant
        cp  /root/keystonerc_demo /home/vagrant
        chown vagrant:vagrant /home/vagrant/keystonerc*
    fi
fi
