# One Node One NIC Openstack Sandbox(centos) Vagrant Setup Guide

## virtulabox vm node
- centOS based vm
- memory: 4-6GB
- CPU: 2
- HD: 50G

You can build it from [centos 7 Minimal iso](http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1708.iso) manually, then followed [RDO packstack guide](https://www.rdoproject.org/install/packstack/) to install one node openstack manually.

Please refer this [one NAT Network NIC manually packstack setup guide](https://github.com/robertluwang/cloud-hands-on-guide/blob/master/dc-vagrant-cloud/one%20NAT%20Network%20NIC%20manually%20packstack%20setup%20guide.md).

Also I created this [centos7 openstack sandbox box](https://app.vagrantup.com/dreamcloud/boxes/ct7os) to help you launch an openstack sandbox quickly using Vagrant.

## use vagrant to launch openstack sandbox
```
$ mkdir vagrant/ctosbox1
$ curl -Lo Vagrantfile
https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.ct7osbox
$ vagrant up
```
- openstack OVS config done
- openstack sandbox vm user/password: vagrant/vagrant
- openstack sandbox default user/password: admin/demo

The last output is instruction how to setup in virtualbox GUI for NAT Network interface.
```
The ovs reconfig done:
ifcfg-eth0
ifcfg-br-ex
/etc/resolv.conf
latest_packstack.conf
keystonerc-*

next action:
1 - power off this vm
2 - create new or use existing NAT Network interface in virtualbox for 172.25.250.0/24, no DHCP
3 - add port forwarding to 172.25.250.10:
127.0.0.1:2222 to 172.25.250.10:22
127.0.0.1:8080 to 172.25.250.10:80
4 - in vm setting, change adapter setting:
Attached to: NAT Network, Name: NatNetworkx
Adapter Type: Paravirtualized Network (virtio-net)
Promiscuous Mode: Allow All
5 - power on vm, ssh to vm to check networking setting as expected
6 - run packstack to update change:
sudo packstack --answer-file latest_packstack.conf
```

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack1.jpg" alt="" width="800" />

## openstack sandbox vm access
you can use any ssh client to access to openstack vm, for example putty.

- use user/password:
```
$ ssh vagrant@localhost -p 2222
```
- use ssh keypair

I used default vagrant public key in openstack sandbox vm, so you need to download vagrant private key from [here](https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant) to match it, place to your laptop shell home/.ssh or install key to putty.

tips to install private key in putty:
```
- putty cannot directly use the private key from vagrant, need to convert key to putty format using puttygen.
- run puttygen, load the vagrant key file, then save private key to vagrant.ppk.
- in putty/SSH/Auth, select vagrant.ppk for private key file for auth.
```
- dashboard GUI
```
http://localhost:8080
```
## verify NAT Network OVS setting
```
[vagrant@ctosbox1 ~]$ sudo cat ifcfg-eth0
DEVICE=eth0
NAME=eth0
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br-ex
ONBOOT=yes
BOOTPROTO=none
```
ifcfg-br-ex as below,
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
vagrant@ctosbox1 ~]$ route -en
Kernel IP routing table
Destination Gateway Genmask Flags MSS Window irtt Iface
0.0.0.0 172.25.250.1 0.0.0.0 UG 0 0 0 br-ex
169.254.0.0 0.0.0.0 255.255.0.0 U 0 0 0 eth0
169.254.0.0 0.0.0.0 255.255.0.0 U 0 0 0 br-ex
172.25.250.0 0.0.0.0 255.255.255.0 U 0 0 0 br-ex
```
## create new project and user
- login as admin
- go to Identity
- create project: lab_project
- create user: lab_user with lab_project, password: demo

## create source file for lab_user

```
[vagrant@ctosbox1 ~]$ cat keystonerc_user
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

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack2.jpg" alt="" width="800" />

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack3.jpg" alt="" width="800" />

## create new image
- as admin
- download cloud image for [cirros](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img) and [fedora](https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2)
- Admin/Compute/Images: create image cirros as QCOW2 format,12MB
- Admin/Compute/Images: create image fedora as QCOW2 format,220MB

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack7.jpg" alt="" width="800" />

## create new flavor for fedora
- as admin
- Admin/Compute/Flavors/Create Flavor: m2.small, 1 vcpu, 512M RAM, 5G Root Disk, 1024M swap disk

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack8.jpg" alt="" width="800" />

## create new private network
- as admin
- Network/Networks: create private network - lab_privnet with lab_project, VXLAN, segment id: 1010
- as lab_user
- Subnet: lab_privsub, 192.168.10.0/24, gateway: 192.168.10.1
- Subnet details: DHCP, 192.168.10.30 to 192.168.10.50, dns: 172.25.250.1, 8.8.8.8

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack4.jpg" alt="" width="800" />

## create router
- as lab_user
- Network/Routers: lab_router with lab_pubnet
- add interface: 192.168.10.0/24, gateway 192.168.10.1 added

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack6.jpg" alt="" width="800" />

Network Topology
<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack9.jpg" alt="" width="800" />

## create new security group
- as lab_user
- Network/Security Groups: lab_sg
- add rule to lab_sg: ICMP,SSH,FTP(TCP 20,21), HTTP for ingress IPv4

<img src="http://dreamcloud.artark.ca/wp-content/uploads/2018/02/1nic-packstack5.jpg" alt="" width="800" />

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
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name       | Status | Task State | Power State | Networks                                 |
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
| 10ef337a-8e79-49c5-be67-fc6c997f61fe | cirros-vm1 | ACTIVE | -          | Running     | lab_privnet=192.168.10.32, 172.25.250.26 |
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
```

## namespace netns test for cirros vm

we can ping floating ip but not private ip, this is expected,

```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ nova list
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name       | Status | Task State | Power State | Networks                                 |
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
| 10ef337a-8e79-49c5-be67-fc6c997f61fe | cirros-vm1 | ACTIVE | -          | Running     | lab_privnet=192.168.10.32, 172.25.250.26 |
+--------------------------------------+------------+--------+------------+-------------+------------------------------------------+
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ping -c 2 192.168.10.32
PING 192.168.10.32 (192.168.10.32) 56(84) bytes of data.
^C
--- 192.168.10.32 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 999ms

[vagrant@ctosbox1 ~(keystone_lab_user)]$ ping -c 2  172.25.250.26
PING 172.25.250.26 (172.25.250.26) 56(84) bytes of data.
64 bytes from 172.25.250.26: icmp_seq=1 ttl=63 time=2.88 ms
64 bytes from 172.25.250.26: icmp_seq=2 ttl=63 time=0.458 ms

--- 172.25.250.26 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.458/1.673/2.888/1.215 ms
```

we can access both private ip/floating ip inside router netns,
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns
qrouter-7d5c225b-a205-450d-8785-f4083d611bcc
qdhcp-f8344d75-19f3-4b18-bf05-659ec5206845
[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns exec qrouter-7d5c225b-a205-450d-8785-f4083d611bcc ping -c 2 192.168.10.32
PING 192.168.10.32 (192.168.10.32) 56(84) bytes of data.
64 bytes from 192.168.10.32: icmp_seq=1 ttl=64 time=1.09 ms
64 bytes from 192.168.10.32: icmp_seq=2 ttl=64 time=0.413 ms

--- 192.168.10.32 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.413/0.752/1.091/0.339 ms
[vagrant@ctosbox1 ~(keystone_lab_user)]$ sudo ip netns exec qrouter-7d5c225b-a205-450d-8785-f4083d611bcc ping -c 2 172.25.250.26
PING 172.25.250.26 (172.25.250.26) 56(84) bytes of data.
64 bytes from 172.25.250.26: icmp_seq=1 ttl=64 time=0.999 ms
64 bytes from 172.25.250.26: icmp_seq=2 ttl=64 time=0.446 ms

--- 172.25.250.26 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.446/0.722/0.999/0.277 ms
```
## ssh to cirros vm in netns
cirros vm can access to Internet,

```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ssh -i /home/vagrant/.ssh/lab-key.pem cirros@172.25.250.26
The authenticity of host '172.25.250.26 (172.25.250.26)' can't be established.
ECDSA key fingerprint is SHA256:2KA5eRDiNSHe7fP/BeVzDw1Xs6QIyaakWx0gHlGeMI4.
ECDSA key fingerprint is MD5:c4:be:d7:e3:15:ca:86:76:a0:37:e9:fe:44:d4:3c:d2.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.25.250.26' (ECDSA) to the list of known hosts.
$

$ cat /etc/resolv.conf
search openstacklocal
nameserver 172.25.250.1
nameserver 8.8.8.8
$ ping google.ca
PING google.ca (172.217.9.131): 56 data bytes
64 bytes from 172.217.9.131: seq=0 ttl=47 time=45.266 ms
```
