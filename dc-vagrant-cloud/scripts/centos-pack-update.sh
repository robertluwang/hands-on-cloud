#!/bin/sh
# centos-pack-update.sh
# centos base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 5th, 2018

nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2`
numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|awk '{print $9}'|cut -d\- -f2|head -2|wc -l`

if [ $numif = 2 ];then
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    
    sed -i "/$natip/s/$natip/$hoip/g" latest_packstack.conf

    packstack --answer-file latest_packstack.conf

    cp  /root/keystonerc_admin /home/vagrant
    cp  /root/keystonerc_demo /home/vagrant
    chown vagrant:vagrant /home/vagrant/keystonerc*
else
    echo "There is only one NAT interface, nothing change on openstack config. You can add another NIC next time."
fi
