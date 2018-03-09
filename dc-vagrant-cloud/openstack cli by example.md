## openstack cli by example 
covers both openstack cli and old cli(neutron/nova/glance).

### create project/user as admin
```
openstack project create myproject
openstack user create myuser --password demo --project myproject
openstack role add --user myuser --project myproject _member_

openstack project create myproject2
openstack user create myuser2 --project myproject2 --password demo
openstack role add --user myuser2 --project myproject2 _member_
```
### create image from file cli
openstack image cli
```
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create demoimg --disk-format qcow2 --file cirros-0.4.0-x86_64-disk.img 
openstack image set demoimg --public 
openstack image save demoimg --file /tmp/demoimg.img   
```
glance image cli
```
glance image-create --name demoimg2 --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare
glance image-show 518e4257-a8fb-4af7-93c5-1f78275cb83c
glance image-update 518e4257-a8fb-4af7-93c5-1f78275cb83c --visibility public
```
### project quota
project quota by openstack quota cli
```
openstack quota set 6af42e05c20c46a697aaa56dd599ea55 --key-pairs 2
```
project quota by nova quota cli
```
nova quota-show --tenant 3985ea75b1ba481cb8399435a2cd2ee1
nova quota-update 3985ea75b1ba481cb8399435a2cd2ee1 --key-pairs 3
```

### create public network admin cli
openstack network cli
```
openstack network create public --project admin  --provider-network-type flat --provider-physical-network extnet --external

openstack subnet create pubsub --project admin --allocation-pool start=172.25.250.30,end=172.25.250.50  --network public --subnet-range 172.25.250.0/24 --no-dhcp --gateway 10.0.2.2 --dns-nameserver 10.0.2.3 --dns-nameserver 8.8.8.8
```
### create private network as admin cli
openstack network cli
```
openstack network create private --project myproject --provider-network-type vxlan --provider-segment 1010
```
neutron net cli
```
neutron net-create private2 --tenant-id 3985ea75b1ba481cb8399435a2cd2ee1 --provider:network_type vxlan --provider:segmentation_id 1020
```
### create private subnet cli
openstack subnet as myuser cli
```    
openstack subnet create privsub --subnet-range 192.168.10.0/24 --dhcp --gateway 192.168.10.25 --network private --allocation-pool start=192.168.10.30,end=192.168.10.50 --dns-nameserver 10.0.2.3 --dns-nameserver 8.8.8.8
```
neutron subnet as myuser2 cli
```
neutron subnet-create private2 192.168.20.0/24 --name privsub2 --gateway 192.168.20.25 --allocation-pool start=192.168.20.30,end=192.168.20.50 --dns-nameserver 10.0.2.3 --dns-nameserver 8.8.8.8  --enable-dhcp
```
### create router cli
openstack router as myuser cli
```
openstack router create router
openstack router set router --external-gateway public
openstack router add subnet router privsub
```
nova router as myuser2 cli
```
neutron router-create router2
neutron router-gateway-set router2 public
neutron router-interface-add router2 privsub2
```
### create security group
openstack security group as myuser cli
```
openstack security group create lab_sg
openstack security group rule create lab_sg --protocol icmp --remote-ip 0.0.0.0/0  
openstack security group rule create lab_sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 
openstack security group rule create lab_sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0  
openstack security group rule create lab_sg --protocol tcp --dst-port 20:21 --remote-ip 0.0.0.0/0   
```
neutron security group as myuser2 cli
```
neutron security-group-create lab_sg2
neutron security-group-rule-create lab_sg2 --direction ingress --ethertype IPv4 --protocol icmp --remote-ip-prefix 0.0.0.0/0
neutron security-group-rule-create lab_sg2 --direction ingress --ethertype IPv4 --protocol tcp --remote-ip-prefix 0.0.0.0/0  --port-range-min 20  --port-range-max 21
neutron security-group-rule-create lab_sg2 --direction ingress --ethertype IPv4 --protocol tcp --remote-ip-prefix 0.0.0.0/0  --port-range-min 22  --port-range-max 22
neutron security-group-rule-create lab_sg2 --direction ingress --ethertype IPv4 --protocol tcp --remote-ip-prefix 0.0.0.0/0  --port-range-min 80  --port-range-max 80
```
### create keypair cli
openstack to create keypair as myuser cli
```
openstack keypair create demokey > ~/.ssh/demokey.pem
chmod 600 ~/.ssh/demokey.pem
```
nova to create keypair as myuser2 cli
```
nova keypair-add demokey2 > ~/.ssh/demokey2.pem
chmod 600 ~/.ssh/demokey2.pem
```
### create vm cli
openstack to create vm1 as myuser cli
```
openstack server create vm1 --image demoimg --flavor m1.tiny --key-name demokey --network private 
```
nova to boot vm2 as myuser2 cli
```
nova boot vm2 --flavor m1.tiny --image demoimg2 --key-name demokey2 --security-groups lab_sg2 --nic net-name=private2
```
### update security group cli
openstack to update sg as myuser cli
```
openstack server add security group vm1 lab_sg
openstack server remove security group vm1 default
```
### floating ip cli
openstack to create floating ip as myuser cli
```
openstack floating ip create public
openstack server add floating ip vm1 172.25.250.38
```
neutron to create floating ip as myuser2 cli
```
neutron floatingip-create public
neutron floatingip-list   // get floating ip id 
neutron port-list         // get private ip port id 
neutron floatingip-associate 0b45c5e8-941c-42d1-873e-4c15fe02275a d135be21-d5af-44bb-a7a2-9198c96e93fb
```
### access to vm cli
access to vm1 as myuser cli
```
sudo ip netns exec qrouter-983bb8f9-04b5-4f7d-9263-5e84217d64d7 ping 172.25.250.38
sudo ip netns exec qrouter-983bb8f9-04b5-4f7d-9263-5e84217d64d7 ssh -i /home/vagrant/.ssh/demokey.pem cirros@172.25.250.38
```
access to vm2 as myuser2 cli
```
sudo ip netns
neutron router-list  // choice right router namespace 
sudo ip netns exec qrouter-529c6323-e548-40ae-9973-205ee18abd63 ping 172.25.250.33
sudo ip netns exec qrouter-529c6323-e548-40ae-9973-205ee18abd63 ssh -i /home/vagrant/.ssh/demokey2.pem cirros@172.25.250.33
```
