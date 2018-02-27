# cloud-init troubleshooting 
## user data sample
```
#cloud-config
runcmd:
 - echo "This is ftp server test by cloud-init." > /etc/motd

packages:
 - vsftpd
```
##  cloud init log
cloud-init debug log, search runcmd will find runcmd script which converted from runcmd section in user-data,

```
[fedora@ftp-server-vm1 log]$ grep runcmd cloud-init.log
2018-02-27 22:00:29,356 - stages.py[DEBUG]: Running module runcmd (<module 'cloudinit.config.cc_runcmd' from '/usr/lib/python3.6/site-packages/cloudinit/config/cc runcmd.py'>) with frequency once-per-instance
2018-02-27 22:00:29,366 - handlers.py[DEBUG]: start: modules-config/config-runcmd: running config-runcmd with frequency once-per-instance
2018-02-27 22:00:29,376 - util.py[DEBUG]: Writing to /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/sem/config_runcmd - wb: [420] 24 bytes
2018-02-27 22:00:29,395 - util.py[DEBUG]: Restoring selinux mode for /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/sem/config_runcmd (recursive=False)
2018-02-27 22:00:29,413 - util.py[DEBUG]: Restoring selinux mode for /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/sem/config_runcmd (recursive=False)
2018-02-27 22:00:29,424 - helpers.py[DEBUG]: Running config-runcmd using lock (<FileLock using file '/var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/sem/config_runcmd'>)
2018-02-27 22:00:29,440 - util.py[DEBUG]: Writing to /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd - wb: [448] 68 bytes
2018-02-27 22:00:29,456 - util.py[DEBUG]: Restoring selinux mode for /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd (recursive=False)
2018-02-27 22:00:29,476 - util.py[DEBUG]: Restoring selinux mode for /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd (recursive=False)
2018-02-27 22:00:29,491 - handlers.py[DEBUG]: finish: modules-config/config-runcmd: SUCCESS: config-runcmd ran successfully
```
have a look the runcmd script, 
```
[fedora@ftp-server-vm1 log]$ ls -ltr /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd
-rwx------. 1 root root 68 Feb 27 22:00 /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd
[fedora@ftp-server-vm1 log]$ sudo cat /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/scripts/runcmd
#!/bin/sh
echo "This is ftp server test by cloud-init." > /etc/motd
```
## cloud-init output log
tail the output log will see progress of cloud-init, it will take some time, 
```
[fedora@ftp-server-vm1 log]$ tail -f cloud-init-output.log
ci-info: +--------+------+---------------+---------------+-------+-------------------+
ci-info: +++++++++++++++++++++++++++++++++Route IPv4 info+++++++++++++++++++++++++++++++++
ci-info: +-------+-----------------+---------------+-----------------+-----------+-------+
ci-info: | Route |   Destination   |    Gateway    |     Genmask     | Interface | Flags |
ci-info: +-------+-----------------+---------------+-----------------+-----------+-------+
ci-info: |   0   |     0.0.0.0     | 192.168.10.25 |     0.0.0.0     |    eth0   |   UG  |
ci-info: |   1   | 169.254.169.254 | 192.168.10.25 | 255.255.255.255 |    eth0   |  UGH  |
ci-info: |   2   |   192.168.10.0  |    0.0.0.0    |  255.255.255.0  |    eth0   |   U   |
ci-info: +-------+-----------------+---------------+-----------------+-----------+-------+
Cloud-init v. 0.7.9 running 'modules:config' at Tue, 27 Feb 2018 22:00:25 +0000. Up 288.65 seconds.
Fedora 27 - x86_64 - Updates                    344 kB/s |  20 MB     00:58
```
be patient will see package vsftpd installed if no issue with script, 
```
Installed:
  vsftpd.x86_64 3.0.3-8.fc27           logrotate.x86_64 3.12.3-4.fc27
```
## cloud instance 
```
cd /var/lib/cloud/instances/7e661919-4705-4445-b532-f947714676b4/
```
will see vm data,
```
[fedora@ftp-server-vm1 7e661919-4705-4445-b532-f947714676b4]$ sudo cat user-data.txt
#cloud-config
runcmd:
 - echo "This is ftp server test by cloud-init." > /etc/motd

packages:
 - vsftpd
```
## troubleshoot
```
- check cloud-init-output.log for cloud-init progress
- go to /var/lib/cloud/instances/<vm-id>, check any issue in side user-data.txt
- verify /var/lib/cloud/instances/<vm-id>/scripts/runcmd
```
