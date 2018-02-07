# build up centos openstack vm node using vagrant

## launch centos 7 vm node 
download Vagrantfile, 
```
mkdir -p vagrant/ctopenstack
cd vagrant/ctopenstack
curl -LO https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile
```
launch centos 7 vm node:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.120.0.21
```
vagrant up
vagrant ssh
```
you can install openstack using packstack as test.

## launch centos openstack vm node with inscript
download Vagrantfile, 
```
mkdir -p vagrant/ctopenstack
cd vagrant/ctopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.inscript
```
launch centos 7 openstack vm node with inscript:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.120.0.21
```
vagrant up
vagrant ssh
```
the centos openstack vm node ready for you.

## launch centos openstack vm node with external script
download Vagrantfile, 
```
mkdir -p vagrant/ctopenstack
cd vagrant/ctopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.pack
```
launch centos 7 openstack vm node with external script:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.120.0.21
```
vagrant up
vagrant ssh
```
the centos openstack vm node ready for you.

## launch centos openstack vm node using ct7os box
this is centos7 based openstack sandbox, download Vagrantfile,
```
mkdir -p vagrant/ctopenstack
cd vagrant/ctopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.ct7os
```
launch using ct7os box:
- hostname: ctopenstack
- memory: 8GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.120.0.21
```
vagrant up
```
sometimes it is hanging at stage:
```
==> ctopenstack: Setting hostname...
==> ctopenstack: Configuring and enabling network interfaces...
```
opened [issue](https://github.com/hashicorp/vagrant/issues/9443) here, as quickly remedy:
```
- ctrl-c to stop "vagrant up" when it is hanging
- power off vm from virtualbox GUI or CLI since "vagrant halt" also will take long time
- run "vagrant up" again it will start 2nd interface easily
```
## launch centos openstack vm node using ct7os box using external ip update script
this is centos7 based openstack sandbox, download Vagrantfile,
```
mkdir -p vagrant/ctopenstack
cd vagrant/ctopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ctopenstack/Vagrantfile.ct7osbox
```
launch using ct7os box:
- hostname: ctopenstack
- memory: 8GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.120.0.21
```
vagrant up
```



