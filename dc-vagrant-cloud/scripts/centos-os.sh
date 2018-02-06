#!/bin/bash
#  centos7 openstack with packstack provision script for packer  
#  Robert Wang
#  Jan 22th, 2018

# step0 presetup
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

# step 1 sw repo
yum install -y centos-release-openstack-pike openstack-utils
yum-config-manager --enable openstack-pike
yum update -y

# step 2 install packstack
yum install -y openstack-packstack

# step3 run packstack
packstack --gen-answer-file=packstack_`date +"%Y-%m-%d"`.conf
cp packstack_`date +"%Y-%m-%d"`.conf latest_packstack.conf

sed -i '/CONFIG_DEFAULT_PASSWORD=/c CONFIG_DEFAULT_PASSWORD=demo' latest_packstack.conf
sed -i '/CONFIG_KEYSTONE_ADMIN_PW=/c CONFIG_KEYSTONE_ADMIN_PW=demo' latest_packstack.conf
sed -i '/CONFIG_KEYSTONE_DEMO_PW=/c CONFIG_KEYSTONE_DEMO_PW=demo' latest_packstack.conf
sed -i '/CONFIG_SWIFT_INSTALL=/c CONFIG_SWIFT_INSTALL=n' latest_packstack.conf
 
packstack --answer-file latest_packstack.conf || echo "packstack exited $? and is suppressed."


