
# One Node Openstack Sandbox Setup Guide

## virtulabox node setting
- centOS based vm
- one NAT NIC: enough for one node packstack installation
- memory: 4-6GB 
- CPU: 2
- HD: 50G 

## use vagrant for openstack
I used vagrant to launch openstack sandbox which installed by packstack.
There is default 1st NIC is NAT for vagrant access, I just used as management ip for openstack.
```
$ mkdir vagrant/ossandbox1
$ curl -Lo Vagrantfile 
https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.ct7osbox
$ vagrant up 
```
this openstack sandbox ready for you:

- openstack OVS config done, use NAT NIC for both openstack and OVS
- dashboard, since this is NAT so cannot directly access to it, just add localhost:8080 to guest 80 in virtualbox GUI, then access http://localhost:8080/dashboard
- openstack sandbox vm user/password: vagrant/vagrant
- openstack sandbox default user/password: admin/demo, demo/demo

## openstack sandbox vm access
you can use any ssh client to access to vm, for example putty.

- use user/password:
```
$ ssh vagrant@localhost:2222
```
- use ssh keypair

I used default vagrant public key in openstack sandbox vm, so you need to download vagrant private from [here](https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant), place to your laptop shell home/.ssh or install to putty.

## verify OVS br-ex
```
[vagrant@ossandbox1 ~]$ ip addr show br-ex
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 08:00:27:3b:90:4d brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe3b:904d/64 scope link
       valid_lft forever preferred_lft forever
```
## verify routing table
```
[vagrant@ossandbox1 ~]$ ip route
default via 10.0.2.2 dev br-ex
10.0.2.0/24 dev br-ex proto kernel scope link src 10.0.2.15
169.254.0.0/16 dev enp0s3 scope link metric 1002
169.254.0.0/16 dev br-ex scope link metric 1005

[vagrant@ossandbox1 ~]$ route -en
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG        0 0          0 br-ex
10.0.2.0        0.0.0.0         255.255.255.0   U         0 0          0 br-ex
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 enp0s3
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 br-ex
```
## clean up all existing project/network 
clean up in this order,

as project user:

- delete instance, release/delete floating ip
- delete router: clear gateway,delete interface then delete router 
- delete private network: delete ports/private subnet then delete private network

as admin user:

- delete public network: delete ports/public subnet then delete public network

## create new project and user
- login as admin
- go to Identity
- create project: lab_project
- create user: lab_user with lab_project, password: redhat

## create source file for lab_user
```
[vagrant@ossandbox1 ]$ cp keystonerc_demo keystonerc_user
[vagrant@ossandbox1 ]$ cat keystonerc_user
unset OS_SERVICE_TOKEN
export OS_USERNAME=lab_user
export OS_PASSWORD='redhat'
export PS1='[\u@\h \W(keystone_lab_user)]\$ '
export OS_AUTH_URL=http://10.0.2.15:5000/v3

export OS_PROJECT_NAME=lab_project
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3
```
then verify source file, 
```
[vagrant@ossandbox1 ]$ source keystonerc_user
[vagrant@ossandbox1 ~(keystone_lab_user)]$ nova list
+----+------+--------+------------+-------------+----------+
| ID | Name | Status | Task State | Power State | Networks |
+----+------+--------+------------+-------------+----------+
+----+------+--------+------------+-------------+----------+

[vagrant@ossandbox1 ~(keystone_user)]$ openstack project list
+----------------------------------+-------------+
| ID                               | Name        |
+----------------------------------+-------------+
| 346f42ef2bdb420b8c15527018b76da8 | lab_project |
+----------------------------------+-------------+
```
## create new public network 
- as admin
- Network/Networks: create public network - lab_pubnet with lab_project, flat with physical interface extnet, enable External Network
- Subnet: lab_pubsub, 172.25.250.0/24, gateway: 172.25.250.254
- Subnet details: no DCHP, 172.25.250.26 to 172.25.250.99, dns: 10.0.2.3, 8.8.8.8

## create new private network 
- as lab_user
- Network/Networks: create private network - lab_privnet with lab_project
- Subnet: lab_privsub, 192.168.10.0/24, gateway: 192.168.10.25
- Subnet details: DHCP, 192.168.10.30 to 192.168.10.50, dns: 10.0.2.3, 8.8.8.8

## create new router 
- as lab_user
- Network/Router: lab_router with public network lab_pubnet 
- add Interface: private network 192.168.10.0/24
- gateway: leave as blank, then gateway 192.168.10.25 will be used as router interface

## create new security group
- as lab_user
- Network/Security Groups:  lab_sg
- add rule to lab_sg: ICMP and SSH for ingress IPv4

## create new keypair
- as lab_user
- Compute/Key Pairs
- save private key to vagrant ~/.ssh/lab-key, chmod 600 lab-key

## create new instance
- as lab_user
- Compute/Instances: lab-vm1, lab_privnet, m1.tiny, cirros, lab_sg, lab-key
- vm assigned private ip 192.168.10.x
- associate floating ip 172.25.250.x

## verify from CLI 
```
[vagrant@ossandbox1 ~(keystone_user)]$ nova list
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name | Status | Task State | Power State | Networks                                 |
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
| e6e9c050-a01f-4eef-851e-2b963d3e18ff | vm1  | ACTIVE | -          | Running     | lab_privnet=192.168.10.40, 172.25.250.34 |
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
[vagrant@ossandbox1 ~(keystone_user)]$ openstack network list
+--------------------------------------+-------------+--------------------------------------+
| ID                                   | Name        | Subnets                              |
+--------------------------------------+-------------+--------------------------------------+
| 6ebdf557-c5b2-4678-82ab-7cf3629b7da5 | lab_privnet | 3ff025c9-d967-4a41-b8a2-451cfb5b778f |
| bf89f606-463c-4f2f-8f95-a5c9b8cbab50 | lab_pubnet  | 96627173-2050-4bb0-9382-e644cae40a46 |
+--------------------------------------+-------------+--------------------------------------+
[vagrant@ossandbox1 ~(keystone_user)]$ openstack router list
+--------------------------------------+------------+--------+-------+-------------+-------+----------------------------------+
| ID                                   | Name       | Status | State | Distributed | HA    | Project                          |
+--------------------------------------+------------+--------+-------+-------------+-------+----------------------------------+
| cc374cbb-81b7-4fff-a3f2-37854a222fd6 | lab_router | ACTIVE | UP    | False       | False | 346f42ef2bdb420b8c15527018b76da8 |
+--------------------------------------+------------+--------+-------+-------------+-------+----------------------------------+
```

## OVS public network access
common issue:

- cannot access to floating ip
- vm instance cannot access to Internet

the behind reason is OVS br-ex external bridge missing public port, in our case is 172.25.250.0/24.

here is remedy to add it manually, 
```
sudo ip addr add 172.25.250.254/24 dev br-ex
sudo iptables -t nat -I POSTROUTING 1 -s 172.25.250.0/24 -j MASQUERADE
```

Now will see it in routing table and br-ex interface, 
```
[vagrant@ossandbox1 ~(keystone_lab_user)]$ route -en
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG        0 0          0 br-ex
10.0.2.0        0.0.0.0         255.255.255.0   U         0 0          0 br-ex
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 enp0s3
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 br-ex
172.25.250.0    0.0.0.0         255.255.255.0   U         0 0          0 br-ex
[vagrant@ossandbox1 ~(keystone_user)]$ ip addr show br-ex
25: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 08:00:27:3b:90:4d brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet 172.25.250.254/24 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::74cb:f8ff:fe47:6049/64 scope link
       valid_lft forever preferred_lft forever
```
## verify access to vm
we can ping and ssh vm floating ip properly now,
```
[vagrant@ossandbox1 ~(keystone_user)]$ ping 172.25.250.34
PING 172.25.250.34 (172.25.250.34) 56(84) bytes of data.
64 bytes from 172.25.250.34: icmp_seq=1 ttl=63 time=10.9 ms
^C
--- 172.25.250.34 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 10.918/10.918/10.918/0.000 ms
[vagrant@ossandbox1 ~(keystone_user)]$ ssh -i /home/vagrant/.ssh/lab-key cirros@172.25.250.34
The authenticity of host '172.25.250.34 (172.25.250.34)' can't be established.
RSA key fingerprint is SHA256:qcLsMKrslFxdrCsRdtg0sYthfF1jQoIOUtpGaCW7oec.
RSA key fingerprint is MD5:67:ea:cf:23:19:ab:96:01:7e:6c:6b:c8:2c:0e:9c:86.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.25.250.34' (RSA) to the list of known hosts.
$
```
## verify vm Internet access
from vm we can access Internet as well,
```
$ route -en
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         192.168.10.25   0.0.0.0         UG        0 0          0 eth0
169.254.169.254 192.168.10.25   255.255.255.255 UGH       0 0          0 eth0
192.168.10.0    0.0.0.0         255.255.255.0   U         0 0          0 eth0
$ cat /etc/resolv.conf
search openstacklocal
nameserver 10.0.2.3
nameserver 8.8.8.8
$ ping 10.0.2.2
PING 10.0.2.2 (10.0.2.2): 56 data bytes
64 bytes from 10.0.2.2: seq=0 ttl=61 time=1.737 ms
^C
--- 10.0.2.2 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.737/1.737/1.737 ms
$ ping google.ca
PING google.ca (135.0.199.38): 56 data bytes
64 bytes from 135.0.199.38: seq=0 ttl=48 time=21.818 ms
```
## new OVS network issue 
after reboot vm, this br-ex setting will be lost, sometimes even add it back, the ssh to floating ip not working in router namespace but ssh to private ip working and vm can access to Internet.

remedy
```
[vagrant@ossandbox1 ~(keystone_user)]$ sudo ip addr add 172.25.250.254/24 dev br-ex
[vagrant@ossandbox1 ~(keystone_user)]$ sudo iptables -t nat -I POSTROUTING 1 -s 172.25.250.0/24 -j MASQUERADE
```
cannot ping/ssh to floating ip in netns, 
```
[vagrant@ossandbox1 ~(keystone_user)]$ sudo ip netns exec qrouter-cc374cbb-81b7-4fff-a3f2-37854a222fd6 ping 172.25.250.34
PING 172.25.250.34 (172.25.250.34) 56(84) bytes of data.
^C
```
however ping/ssh working for private ip in netns, and vm Internet access fine.
```
[vagrant@ossandbox1 ~(keystone_user)]$ sudo ip netns exec qrouter-cc374cbb-81b7-4fff-a3f2-37854a222fd6 ssh -i /home/vagrant/.ssh/lab-key cirros@192.168.10.40
$ ping google.ca
PING google.ca (135.0.199.249): 56 data bytes
64 bytes from 135.0.199.249: seq=0 ttl=40 time=39.504 ms
64 bytes from 135.0.199.249: seq=1 ttl=40 time=43.974 ms
```
Found too many similar post in Internet but no valid solution found yet.




