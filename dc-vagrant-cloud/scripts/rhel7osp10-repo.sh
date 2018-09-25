#!/bin/bash
# rhel7osp10-repo.sh
# rhel7.3 repo register script
# Robert Wang @github.com/robertluwang
# Sept 24th, 2018 
# $1 - rhel dev account user
# $2 - rhel dev account password
subscription-manager register --username $1 --password $2 --auto-attach
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-7-server-rpms
subscription-manager repos --enable=rhel-7-server-rh-common-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-openstack-10-rpms
subscription-manager repos --enable=rhel-7-server-openstack-10-devtools-rpms
yum install -y yum-utils  
yum update -y 