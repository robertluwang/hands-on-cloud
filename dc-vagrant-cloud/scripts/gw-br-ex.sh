#!/bin/bash
# ovs public network remedy script
# Robert Wang
# Feb 14th, 2018
# add public network gateway to br-ex
# enable NAT in iptables
# $1 - gateway ip

if [ $# -eq 0 ]; then
    echo
    echo "ovs public network remedy script"
    echo "add public network gateway to br-ex and enable NAT in iptables"
    echo "to allow access floating ip and vm access to Internet"
    echo
    echo "Usage:"
    echo "gw-br-ex.sh  <public network gateway ip>"
    echo
    exit 1
fi

gw=$1
pubnet=`echo $gw|cut -d. -f1,2,3`.0

sudo ip addr add $gw/24 dev br-ex

sudo iptables -t nat -I POSTROUTING 1 -s $pubnet/24 -j MASQUERADE
