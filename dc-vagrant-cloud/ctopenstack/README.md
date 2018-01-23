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
