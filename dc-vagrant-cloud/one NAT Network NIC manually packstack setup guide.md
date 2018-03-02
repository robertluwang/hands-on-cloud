# one NAT Network NIC manually packstack setup guide

NAT Network is new virtualbox adapter, between NAT and Hostonly, it is type of NAT but can have any static ip address.

NAT Network is best choice if you consider one NIC solution for openstack sandbox setup.

## virtualbox vm 
```
- create new vm as Redhat x86 64bit
- memory: 4GB 
- CPU: 2
- HD: 50G
- Network
1) create new NAT Network from virtualbox File/Preferences/Network
    - NAT Network adaptor: NatNetwork1  172.25.250.0/24, no DHCP
    - NatNetwork1 port forward: 
    127.0.0.1:2222 to 172.25.250.10:2222
    127.0.0.1:8080 to 172.25.250.10:80
2) change in vm setting/Network
    - Attached to: NAT Network, Name: NatNetwork1
    - Adapter Type: Paravirtualized Network (virtio-net) 
    - Promiscuous Mode: Allow All 
```

## install centos7 manually 
You can download centos7 iso from [centos 7 Minimal iso](http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1708.iso), manually install it.

- hostname: centos7
- user/password: centos/centos

## sudo user centos 
```
$ sudo su 
# sudo usermod -aG centos centos
# touch /etc/sudoers.d/centos
# echo '%centos ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/centos
# chmod 0440 /etc/sudoers.d/centos
```
verify sudo user,
```
$ su - centos
$ sudo pwd
/home/centos
switch to root
$ sudo su
```
most of case we use root for openstack CLI. 

## disable firewalld/NetManager
```
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network
```
update,
```
yum -y update
reboot
```
## install RDO
install RDO repo,
```
[root@centos7 ~]$ yum install -y https://rdoproject.org/repos/rdo-release.rpm
Loaded plugins: fastestmirror
rdo-release.rpm                                                                                        | 5.6 kB  00:00:00
Examining /var/tmp/yum-root-Fd0FkY/rdo-release.rpm: rdo-release-pike-1.noarch
Marking /var/tmp/yum-root-Fd0FkY/rdo-release.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package rdo-release.noarch 0:pike-1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================
 Package                         Arch                       Version                    Repository                        Size
==============================================================================================================================
Installing:
 rdo-release                     noarch                     pike-1                     /rdo-release                     3.1 k

Transaction Summary
==============================================================================================================================
Install  1 Package

Total size: 3.1 k
Installed size: 3.1 k
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : rdo-release-pike-1.noarch                                                                                  1/1
  Verifying  : rdo-release-pike-1.noarch                                                                                  1/1

Installed:
  rdo-release.noarch 0:pike-1

Complete!
```
update will install dependencies,
```
[root@centos7 ~]$ yum update -y
Loaded plugins: fastestmirror
openstack-pike                                                                                         | 2.9 kB  00:00:00
rdo-qemu-ev                                                                                            | 2.9 kB  00:00:00
(1/2): rdo-qemu-ev/x86_64/primary_db                                                                   |  33 kB  00:00:00
(2/2): openstack-pike/x86_64/primary_db                                                                | 996 kB  00:00:02
Loading mirror speeds from cached hostfile
 * base: centos.mirror.rafal.ca
 * extras: centos.mirror.rafal.ca
 * updates: centos.mirror.rafal.ca
Resolving Dependencies
--> Running transaction check
---> Package mariadb-libs.x86_64 1:5.5.56-2.el7 will be updated
---> Package mariadb-libs.x86_64 3:10.1.20-2.el7 will be an update
--> Processing Dependency: mariadb-common(x86-64) = 3:10.1.20-2.el7 for package: 3:mariadb-libs-10.1.20-2.el7.x86_64
--> Running transaction check
---> Package mariadb-common.x86_64 3:10.1.20-2.el7 will be installed
--> Processing Dependency: /etc/my.cnf for package: 3:mariadb-common-10.1.20-2.el7.x86_64
--> Running transaction check
---> Package mariadb-config.x86_64 3:10.1.20-2.el7 will be installed
---> Package mariadb-libs.x86_64 1:5.5.56-2.el7 will be updated
---> Package mariadb-libs.x86_64 1:5.5.56-2.el7 will be updated
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================
 Package                        Arch                   Version                           Repository                      Size
==============================================================================================================================
Updating:
 mariadb-libs                   x86_64                 3:10.1.20-2.el7                   openstack-pike                 643 k
Installing for dependencies:
 mariadb-common                 x86_64                 3:10.1.20-2.el7                   openstack-pike                  63 k
 mariadb-config                 x86_64                 3:10.1.20-2.el7                   openstack-pike                  26 k

Transaction Summary
==============================================================================================================================
Install             ( 2 Dependent packages)
Upgrade  1 Package

Total download size: 732 k
Downloading packages:
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
warning: /var/cache/yum/x86_64/7/openstack-pike/packages/mariadb-config-10.1.20-2.el7.x86_64.rpm: Header V4 RSA/SHA1 Signature, key ID 764429e6: NOKEY
Public key for mariadb-config-10.1.20-2.el7.x86_64.rpm is not installed
(1/3): mariadb-config-10.1.20-2.el7.x86_64.rpm                                                         |  26 kB  00:00:00
(2/3): mariadb-common-10.1.20-2.el7.x86_64.rpm                                                         |  63 kB  00:00:00
(3/3): mariadb-libs-10.1.20-2.el7.x86_64.rpm                                                           | 643 kB  00:00:01
------------------------------------------------------------------------------------------------------------------------------
Total                                                                                         334 kB/s | 732 kB  00:00:02
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud
Importing GPG key 0x764429E6:
 Userid     : "CentOS Cloud SIG (http://wiki.centos.org/SpecialInterestGroup/Cloud) <security@centos.org>"
 Fingerprint: 736a f511 6d9c 40e2 af6b 074b f9b9 fee7 7644 29e6
 Package    : rdo-release-pike-1.noarch (installed)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : 3:mariadb-config-10.1.20-2.el7.x86_64                                                                      1/4
  Installing : 3:mariadb-common-10.1.20-2.el7.x86_64                                                                      2/4
  Updating   : 3:mariadb-libs-10.1.20-2.el7.x86_64                                                                        3/4
  Cleanup    : 1:mariadb-libs-5.5.56-2.el7.x86_64                                                                         4/4
  Verifying  : 3:mariadb-common-10.1.20-2.el7.x86_64                                                                      1/4
  Verifying  : 3:mariadb-config-10.1.20-2.el7.x86_64                                                                      2/4
  Verifying  : 3:mariadb-libs-10.1.20-2.el7.x86_64                                                                        3/4
  Verifying  : 1:mariadb-libs-5.5.56-2.el7.x86_64                                                                         4/4

Dependency Installed:
  mariadb-common.x86_64 3:10.1.20-2.el7                         mariadb-config.x86_64 3:10.1.20-2.el7

Updated:
  mariadb-libs.x86_64 3:10.1.20-2.el7

Complete!
```

## install openvswitch
```
[root@centos7 ~]$ yum install -y openvswitch
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos.mirror.rafal.ca
 * extras: centos.mirror.rafal.ca
 * updates: centos.mirror.rafal.ca
Resolving Dependencies
--> Running transaction check
---> Package openvswitch.x86_64 1:2.7.3-1.1fc27.el7 will be installed
--> Processing Dependency: libpcap.so.1()(64bit) for package: 1:openvswitch-2.7.3-1.1fc27.el7.x86_64
--> Running transaction check
---> Package libpcap.x86_64 14:1.5.3-9.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================
 Package                     Arch                   Version                              Repository                      Size
==============================================================================================================================
Installing:
 openvswitch                 x86_64                 1:2.7.3-1.1fc27.el7                  openstack-pike                 4.6 M
Installing for dependencies:
 libpcap                     x86_64                 14:1.5.3-9.el7                       base                           138 k

Transaction Summary
==============================================================================================================================
Install  1 Package (+1 Dependent package)

Total download size: 4.8 M
Installed size: 21 M
Downloading packages:
(1/2): libpcap-1.5.3-9.el7.x86_64.rpm                                                                  | 138 kB  00:00:10
(2/2): openvswitch-2.7.3-1.1fc27.el7.x86_64.rpm                                                        | 4.6 MB  00:00:16
------------------------------------------------------------------------------------------------------------------------------
Total                                                                                         297 kB/s | 4.8 MB  00:00:16
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : 14:libpcap-1.5.3-9.el7.x86_64                                                                              1/2
  Installing : 1:openvswitch-2.7.3-1.1fc27.el7.x86_64                                                                     2/2
  Verifying  : 14:libpcap-1.5.3-9.el7.x86_64                                                                              1/2
  Verifying  : 1:openvswitch-2.7.3-1.1fc27.el7.x86_64                                                                     2/2

Installed:
  openvswitch.x86_64 1:2.7.3-1.1fc27.el7

Dependency Installed:
  libpcap.x86_64 14:1.5.3-9.el7

Complete!
[root@centos7 ~]$ systemctl start openvswitch
```
## OVS setup
update NIC interface,
```
[root@centos7 ~]$ cd /etc/sysconfig/network-scripts
[root@centos7 network-scripts]$ sudo cp ifcfg-eth0 ifcfg-br-ex
[root@centos7 network-scripts]$ cat ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex

[root@centos7 network-scripts]$ cat ifcfg-br-ex
DEVICE=br-ex
BOOTPROTO=static
ONBOOT=yes
TYPE=OVSBridge
DEVICETYPE=ovs
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
IPADDR=172.25.250.10
NETMASK=255.255.255.0
GATEWAY=172.25.250.1
DNS1=172.25.250.1
DNS2=8.8.8.8
```
restart network to make change,
```
systemctl restart network 
```
check interface, ip 172.25.250.10 moved from eth0 to br-ex,
```
[root@centos7 network-scripts]$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 08:00:27:b4:a5:ff brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:feb4:a5ff/64 scope link
       valid_lft forever preferred_lft forever
3: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether 62:ed:f1:14:d8:26 brd ff:ff:ff:ff:ff:ff
4: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 08:00:27:b4:a5:ff brd ff:ff:ff:ff:ff:ff
    inet 172.25.250.10/24 brd 172.25.250.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::64ba:2aff:fe15:524d/64 scope link
       valid_lft forever preferred_lft forever
```
check ovs-vsctl status, 
```
[root@centos7 network-scripts]$ ovs-vsctl show
fca9ea11-2e86-44f5-8e07-76b0dbfd4bf2
    Bridge br-ex
        Port br-ex
            Interface br-ex
                type: internal
        Port "eth0"
            Interface "eth0"
    ovs_version: "2.7.3"
```
## install openstack 
check the repo, should see openstack-pike, 
```
[root@centos7 network-scripts]$ yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos.mirror.iweb.ca
 * extras: centos.mirror.iweb.ca
 * updates: centos.mirror.iweb.ca
repo id                                                   repo name                                                     status
base/7/x86_64                                             CentOS-7 - Base                                               9,591
extras/7/x86_64                                           CentOS-7 - Extras                                               390
openstack-pike/x86_64                                     OpenStack Pike Repository                                     2,391
rdo-qemu-ev/x86_64                                        RDO CentOS-7 - QEMU EV                                           43
updates/7/x86_64                                          CentOS-7 - Updates                                            1,941
repolist: 14,356
```
install packstack,
```
[root@centos7 network-scripts]$ yum -y install openstack-packstack
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos.mirror.rafal.ca
 * extras: centos.mirror.rafal.ca
 * updates: centos.mirror.rafal.ca
Resolving Dependencies
--> Running transaction check
---> Package openstack-packstack.noarch 1:11.0.1-1.el7 will be installed
```
generate answer file for further configuration, 
```
[root@centos7 ~]# packstack --gen-answer-file=/root/answers.txt
```
here is minimal change example, 
```
[root@centos7 ~]# cat answers.txt 
CONFIG_DEFAULT_PASSWORD=redhat
CONFIG_KEYSTONE_ADMIN_PW=redhat
CONFIG_SWIFT_INSTALL=n
CONFIG_CINDER_INSTALL=n
CONFIG_NEUTRON_ML2_VNI_RANGES=1000:2000
CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=extnet:br-ex
CONFIG_PROVISION_DEMO=n
CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:eth0
```
Now let's run packstack with config file, it will take around 20-30 mins, 
```
[root@centos7 ~]# packstack --answer-file /root/answers.txt
Welcome to the Packstack setup utility

The installation log file is available at: /var/tmp/packstack/20180302-022249-J3ty4Y/openstack-setup.log

Installing:
Clean Up                                             [ DONE ]
Discovering ip protocol version                      [ DONE ]
Setting up ssh keys                                  [ DONE ]
Preparing servers                                    [ DONE ]
Pre installing Puppet and discovering hosts' details [ DONE ]
Preparing pre-install entries                        [ DONE ]
Setting up CACERT                                    [ DONE ]
Preparing AMQP entries                               [ DONE ]
Preparing MariaDB entries                            [ DONE ]
Fixing Keystone LDAP config parameters to be undef if empty[ DONE ]
Preparing Keystone entries                           [ DONE ]
Preparing Glance entries                             [ DONE ]
Preparing Nova API entries                           [ DONE ]
Creating ssh keys for Nova migration                 [ DONE ]
Gathering ssh host keys for Nova migration           [ DONE ]
Preparing Nova Compute entries                       [ DONE ]
Preparing Nova Scheduler entries                     [ DONE ]
Preparing Nova VNC Proxy entries                     [ DONE ]
Preparing OpenStack Network-related Nova entries     [ DONE ]
Preparing Nova Common entries                        [ DONE ]
Preparing Neutron LBaaS Agent entries                [ DONE ]
Preparing Neutron API entries                        [ DONE ]
Preparing Neutron L3 entries                         [ DONE ]
Preparing Neutron L2 Agent entries                   [ DONE ]
Preparing Neutron DHCP Agent entries                 [ DONE ]
Preparing Neutron Metering Agent entries             [ DONE ]
Checking if NetworkManager is enabled and running    [ DONE ]
Preparing OpenStack Client entries                   [ DONE ]
Preparing Horizon entries                            [ DONE ]
Preparing Gnocchi entries                            [ DONE ]
Preparing Redis entries                              [ DONE ]
Preparing Ceilometer entries                         [ DONE ]
Preparing Aodh entries                               [ DONE ]
Preparing Puppet manifests                           [ DONE ]
Copying Puppet modules and manifests                 [ DONE ]
Applying 172.25.250.10_controller.pp
172.25.250.10_controller.pp:                         [ DONE ]
Applying 172.25.250.10_network.pp
172.25.250.10_network.pp:                            [ DONE ]
Applying 172.25.250.10_compute.pp
172.25.250.10_compute.pp:                            [ DONE ]
Applying Puppet manifests                            [ DONE ]
Finalizing                                           [ DONE ]

 **** Installation completed successfully ******

Additional information:
 * Time synchronization installation was skipped. Please note that unsynchronized time on server instances might be problem for some OpenStack component   s.
 * File /root/keystonerc_admin has been created on OpenStack client host 172.25.250.10. To use the command line tools you need to source the file.
 * To access the OpenStack Dashboard browse to http://172.25.250.10/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
 * The installation log file is available at: /var/tmp/packstack/20180302-022249-J3ty4Y/openstack-setup.log
 * The generated manifests are available at: /var/tmp/packstack/20180302-022249-J3ty4Y/manifests
```
## dashboard GUI 
Since we use NAT Network, will use localhost:8080 to map guest 172.25.250.10:80, type url in laptop browser, 
```
http://localhost:8080/dashboard
```
## create new project and user
- login as admin
- go to Identity
- create project: lab_project
- create user: lab_user with lab_project, password: redhat

## create source file for lab_user
```
[root@centos7 ~]# cat keystonerc_user
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
[root@centos7 ~]# source keystonerc_user

## create new public network 
- as admin
- Network/Networks: create public network - lab_pubnet with lab_project, flat with physical interface extnet, enable External Network
- Subnet: lab_pubsub, 172.25.250.0/24, gateway: 172.25.250.1
- Subnet details: no DCHP, 172.25.250.26 to 172.25.250.99, dns: 172.25.250.1, 8.8.8.8

## create new image
- as admin 
- download cloud image for [cirros](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img)
- Admin/Compute/Images: create image cirros as QCOW2 format,12MB 

## create new private network 
- as admin
- Network/Networks: create private network - lab_privnet with lab_project, VXLAN, segment id: 1010
- as lab_user
- Subnet: lab_privsub, 192.168.10.0/24, gateway: 192.168.10.25
- Subnet details: DHCP, 192.168.10.30 to 192.168.10.50, dns: 172.25.250.1, 8.8.8.8

## create router 
- as lab_user
- Network/Routers: lab_router with lab_pubnet 
- add interface: 192.168.10.0/24, gateway 192.168.10.25 added

## create new security group
- as lab_user
- Network/Security Groups:  lab_sg
- add rule to lab_sg: ICMP,SSH for ingress IPv4

## create new keypair
- as lab_user
- Compute/Key Pairs
- save private key to vagrant ~/.ssh/lab-key.pem, chmod 600 lab-key.pem

## create new cirros instance
- as lab_user
- Compute/Instances: vm1, lab_privnet, m1.tiny, cirros, lab_sg, lab-key.pem
- vm assigned private ip 192.168.10.35
- associate floating ip 172.25.250.34

## source file for lab_user
```
[root@centos7 ~(keystone_lab_user)]# cat keystonerc_user
unset OS_SERVICE_TOKEN
    export OS_USERNAME=lab_user
    export OS_PASSWORD='redhat'
    export OS_AUTH_URL=http://172.25.250.10:5000/v3
    export PS1='[\u@\h \W(keystone_lab_user)]\$ '

export OS_PROJECT_NAME=lab_project
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3

[root@centos7 ~]# source keystonerc_user
```
## openstack CLI 
```
[root@centos7dev ~(keystone_lab_user)]# nova list
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name | Status | Task State | Power State | Networks                                 |
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
| 9cdc425e-1eda-4e10-a7c9-75896091cf1f | vm1  | ACTIVE | -          | Running     | lab_privnet=192.168.10.35, 172.25.250.34 |
+--------------------------------------+------+--------+------------+-------------+------------------------------------------+
```
## ssh to vm floating ip
```
[root@centos7dev ~(keystone_lab_user)]# ping 172.25.250.34
PING 172.25.250.34 (172.25.250.34) 56(84) bytes of data.
64 bytes from 172.25.250.34: icmp_seq=1 ttl=63 time=4.80 ms
64 bytes from 172.25.250.34: icmp_seq=2 ttl=63 time=0.719 ms

[root@centos7dev ~(keystone_lab_user)]# ssh -i ~/.ssh/lab-key.pem cirros@172.25.250.34

$ cat /etc/resolv.conf
search openstacklocal
nameserver 172.25.250.1
nameserver 8.8.8.8

$ route -en
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         192.168.10.25   0.0.0.0         UG        0 0          0 eth0
169.254.169.254 192.168.10.25   255.255.255.255 UGH       0 0          0 eth0
192.168.10.0    0.0.0.0         255.255.255.0   U         0 0          0 eth0
```
verify vm Internet access, 
```
$ ping google.ca
PING google.ca (172.217.0.99): 56 data bytes
64 bytes from 172.217.0.99: seq=0 ttl=40 time=35.139 ms
```

