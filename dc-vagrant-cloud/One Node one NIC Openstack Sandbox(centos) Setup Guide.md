
# One Node One NIC Openstack Sandbox(centos) Setup Guide

## virtulabox vm node
- centOS based vm
- memory: 4-6GB 
- CPU: 2
- HD: 50G

You can build it from [centos 7 Minimal iso](http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1708.iso) manually, then followed [RDO packstack guide](https://www.rdoproject.org/install/packstack/) to install one node openstack manually.

Also I created this [centos7 openstack sandbox box](https://app.vagrantup.com/dreamcloud/boxes/ct7os) to help you launch a test openstack sandbox in few mins using Vagrant.

## use vagrant to launch openstack sandbox
```
$ mkdir vagrant/ossandbox1
$ curl -Lo Vagrantfile 
https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.ct7osbox
$ vagrant up 
```
- openstack OVS config done, use NAT NIC for both openstack and OVS br-ex
- openstack sandbox vm user/password: vagrant/vagrant
- openstack sandbox default user/password: admin/demo

## openstack interface setup in virtualbox 
There are few network adaptor options for one node oepnstack setup, NAT Network, Hostonly + NAT, or bridged, we do demo NAT Network one NIC here.
- create new NAT Network from virtualbox File/Preferences/Network
    - NAT Network adaptor: NatNetwork1  172.25.250.0/24, no DHCP
    - NatNetwork1 port forward: 
    127.0.0.1:2222 to 172.25.250.10:2222
    127.0.0.1:8080 to 172.25.250.10.80
- change in vm setting/Network
    - Attached to: NAT Network, Name: NatNetwork1
    - Adapter Type: Paravirtualized Network (virtio-net) for better network performance 
    - Promiscuous Mode: Allow All, needed for OVS traffic 

## openstack sandbox vm access
you can use any ssh client to access to openstack vm, for example putty.

- use user/password:
```
$ ssh vagrant@localhost -p 2222
```
- use ssh keypair

I used default vagrant public key in openstack sandbox vm, so you need to download vagrant private from [here](https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant), place to your laptop shell home/.ssh or install to putty.

## verify NAT Network OVS setting
```
[vagrant@ctosbox1 ~]$ cd /etc/sysconfig/network-scripts/
[vagrant@ctosbox1 network-scripts]$ ls -ltr|grep ifcfg
-rw-r--r--. 1 root root   254 Feb 22 18:13 ifcfg-lo
-rw-r--r--. 1 root root    93 Feb 22 21:39 ifcfg-enp0s3
-rw-r--r--. 1 root root   217 Feb 22 21:39 ifcfg-br-ex
```
the NAT interface file is enp0s3 but from ip addr, cannot find enp0s3 but there is eth0 and not up, this is because when change NAT Network adapter type, the interface changed to eth0.

we rename enp0s3 to eth0 and update name in ifcfg-eth0, 
```
[vagrant@ctosbox1 ~]$ sudo mv ifcfg-enp0s3 ifcfg-eth0 
[vagrant@ctosbox1 ~]$ sudo cat ifcfg-eth0
DEVICE=eth0
NAME=eth0
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br-ex
ONBOOT=yes
BOOTPROTO=none
```
also update ifcfg-br-ex from dhcp to static as below,
```
[vagrant@ctosbox1 ~]$ sudo cat ifcfg-br-ex
ONBOOT="yes"
NETBOOT="yes"
IPADDR=172.25.250.10
NETMASK=255.255.255.0
GATEWAY=172.25.250.1
DEVICE=br-ex
NAME=br-ex
DEVICETYPE=ovs
OVSBOOTPROTO="static"
TYPE=OVSBridge
OVS_EXTRA="set bridge br-ex fail_mode=standalone"
```
restart network to make the change,
```
sudo systemctl restart network.service
```
ip addr
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 08:00:27:b4:a5:ff brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:feb4:a5ff/64 scope link
       valid_lft forever preferred_lft forever

4: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 08:00:27:b4:a5:ff brd ff:ff:ff:ff:ff:ff
    inet 172.25.250.10/24 brd 172.25.250.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feb4:a5ff/64 scope link
       valid_lft forever preferred_lft forever
```

## verify routing table
```
vagrant@ctosbox1]$ route -en
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.25.250.1    0.0.0.0         UG        0 0          0 br-ex
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 br-ex
172.25.250.0    0.0.0.0         255.255.255.0   U         0 0          0 br-ex
```

## create new project and user
- login as admin
- go to Identity
- create project: lab_project
- create user: lab_user with lab_project, password: demo

## create source file for lab_user
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ cat keystonerc_user
unset OS_SERVICE_TOKEN
    export OS_USERNAME=lab_user
    export OS_PASSWORD='demo'
    export OS_AUTH_URL=http://172.25.250.10:5000/v3
    export PS1='[\u@\h \W(keystone_lab_user)]\$ '

export OS_PROJECT_NAME=lab_project
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3
```
[vagrant@ctosbox1 ~]$ source keystonerc_user

## create new public network 
- as admin
- Network/Networks: create public network - lab_pubnet with lab_project, flat with physical interface extnet, enable External Network
- Subnet: lab_pubsub, 172.25.250.0/24, gateway: 172.25.250.1
- Subnet details: no DCHP, 172.25.250.26 to 172.25.250.99, dns: 172.25.250.1, 8.8.8.8

## create new private network 
- as lab_user
- Network/Networks: create private network - lab_privnet with lab_project
- Subnet: lab_privsub, 192.168.10.0/24, gateway: 192.168.10.1
- Subnet details: DHCP, 192.168.10.30 to 192.168.10.50, dns: 172.25.250.1, 8.8.8.8

## create new security group
- as lab_user
- Network/Security Groups:  lab_sg
- add rule to lab_sg: ICMP,SSH,FTP(TCP 20,21), HTTP for ingress IPv4

## create new keypair
- as lab_user
- Compute/Key Pairs
- save private key to vagrant ~/.ssh/lab-key.pem, chmod 600 lab-key.pem

## create new cirros instance
- as lab_user
- Compute/Instances: vm1, lab_privnet, m1.tiny, cirros, lab_sg, lab-key.pem
- vm assigned private ip 192.168.10.35
- associate floating ip 172.25.250.30

## verify from CLI 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ nova list
+--------------------------------------+--------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name   | Status | Task State | Power State | Networks                                 |
+--------------------------------------+--------+--------+------------+-------------+------------------------------------------+
| c81710b1-4909-4382-852f-7fbd82c1a15b | ub-vm1 | ACTIVE | -          | Running     | lab_privnet=192.168.10.34, 172.25.250.32 |
| dea8a148-f470-4325-8bf0-ee9ce8cdda7f | vm2    | ACTIVE | -          | Running     | lab_privnet=192.168.10.35, 172.25.250.30 |
+--------------------------------------+--------+--------+------------+-------------+------------------------------------------+
```

## namespace netns test for cirros vm  

we can ping floating ip but not private ip, this is expected, 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ping 192.168.10.35
PING 192.168.10.35 (192.168.10.35) 56(84) bytes of data.
^C
--- 192.168.10.35 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 999ms

[vagrant@ctosbox1 ~(keystone_lab_user)]$ ping 172.25.250.30
PING 172.25.250.30 (172.25.250.30) 56(84) bytes of data.
64 bytes from 172.25.250.30: icmp_seq=1 ttl=63 time=6.59 ms
64 bytes from 172.25.250.30: icmp_seq=2 ttl=63 time=0.875 ms
--- 172.25.250.30 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.875/3.737/6.599/2.862 ms
```
we can access private ip inside netns, 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns
qrouter-7d5c225b-a205-450d-8785-f4083d611bcc
qdhcp-f8344d75-19f3-4b18-bf05-659ec5206845

[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns exec qrouter-7d5c225b-a205-450d-8785-f4083d611bcc ping 192.168.10.35
PING 192.168.10.35 (192.168.10.35) 56(84) bytes of data.
64 bytes from 192.168.10.35: icmp_seq=1 ttl=64 time=1.40 ms
```
## ssh to cirros vm in netns 
cirros vm can access to Internet, 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns exec qrouter-7d5c225b-a205-450d-8785-f4083d611bcc ssh -i /home/vagrant/.ssh/lab-key.pem cirros@172.25.250.30
$

$ cat /etc/resolv.conf
search openstacklocal
nameserver 172.25.250.1
nameserver 8.8.8.8
$ ping 172.25.250.1
PING 172.25.250.1 (172.25.250.1): 56 data bytes
64 bytes from 172.25.250.1: seq=0 ttl=254 time=2.227 ms
64 bytes from 172.25.250.1: seq=1 ttl=254 time=2.159 ms

$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: seq=0 ttl=41 time=28.814 ms

$ ping google.ca
PING google.ca (172.217.9.131): 56 data bytes
64 bytes from 172.217.9.131: seq=0 ttl=47 time=42.956 ms
64 bytes from 172.217.9.131: seq=1 ttl=47 time=48.956 ms
```



