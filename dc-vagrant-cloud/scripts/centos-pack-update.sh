#!/bin/sh
# centos-pack-update.sh
# centos base openstack box packstack ip date script for packer
# Robert Wang @github.com/robertluwang
# Feb 5th, 2018

numif=`ip link |grep BROADCAST|cut -d: -f2|head -2|wc -l`

if [ $numif = 2 ];then
    natif=`ip link |grep BROADCAST|cut -d: -f2|head -1`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    hoif=`ip link |grep BROADCAST|cut -d: -f2|head -2|tail -1`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    
    sed -i "/$natip/s/$natip/$hoip/g" latest_packstack.conf

    packstack --answer-file latest_packstack.conf

    cp  /root/keystonerc_admin /home/vagrant
    cp  /root/keystonerc_demo /home/vagrant
    chown vagrant:vagrant /home/vagrant/keystonerc*
else
    echo "There is only one NAT interface, nothing change on openstack config. You can add another NIC next time."
fi
