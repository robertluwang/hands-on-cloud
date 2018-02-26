# Create ftp server using cloud-init

## openstack sandbox setup


## create ftp server 
- new instance: ftp-server-vm1, m2.small
- Configuration/Customization Script
```
#cloud-config
runcmd:
 - echo "This is ftp server test using cloud-init." > /etc/motd 

packages:
 - vsftpd
```
![](1nic-packstack10.jpg)

![](1nic-packstack11.jpg)

## monitor instance booting log 
Project/Compute/Instances/Log/View Full Log

![](1nic-packstack12.jpg)

ping floating ip not working due to it will take longer time than cirros, can check progress from above gui log, 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ nova list
+--------------------------------------+----------------+--------+------------+-------------+------------------------------------------+
| ID                                   | Name           | Status | Task State | Power State | Networks                                 |
+--------------------------------------+----------------+--------+------------+-------------+------------------------------------------+
| 10ef337a-8e79-49c5-be67-fc6c997f61fe | cirros-vm1     | ACTIVE | -          | Running     | lab_privnet=192.168.10.32, 172.25.250.26 |
| 3a24c70b-3c83-46e0-86c6-dadf8d8384b9 | ftp-server-vm1 | ACTIVE | -          | Running     | lab_privnet=192.168.10.41, 172.25.250.30 |
+--------------------------------------+----------------+--------+------------+-------------+------------------------------------------+
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ping 172.25.250.30
PING 172.25.250.30 (172.25.250.30) 56(84) bytes of data.
64 bytes from 172.25.250.30: icmp_seq=1 ttl=63 time=4.57 ms
64 bytes from 172.25.250.30: icmp_seq=2 ttl=63 time=3.77 ms
```
## ssh to fedora ftp server vm
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ssh -i /home/vagrant/.ssh/lab-key.pem fedora@172.25.250.30
The authenticity of host '172.25.250.30 (172.25.250.30)' can't be established.
ECDSA key fingerprint is SHA256:uUwluQHLufgfBP6LNj1stLLTh3+/zPdD/Jtn/j2v/WA.
ECDSA key fingerprint is MD5:6d:6f:a2:33:00:41:55:29:64:6f:92:38:31:94:31:bd.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.25.250.30' (ECDSA) to the list of known hosts.
[fedora@ftp-server-vm1 ~]$
```
test Internet access in side fedora vm, 
```
[fedora@ftp-server-vm1 ~]$ ping google.ca
PING google.ca (172.217.9.131) 56(84) bytes of data.
64 bytes from dfw25s26-in-f3.1e100.net (172.217.9.131): icmp_seq=1 ttl=47 time=49.1 ms
64 bytes from dfw25s26-in-f3.1e100.net (172.217.9.131): icmp_seq=2 ttl=47 time=49.8 ms
```
## fedora cloud-init
- check /etc/motd
```
[fedora@ftp-server-vm1 ftp]$ cat /etc/motd
This is ftp server test using cloud-init.
```
- cloud-init debug log 
```
/var/log/cloud-init.log
```
- cloud-init output log
```
/var/log/cloud-init-output.log

you will see vxftpd installed
Installed:
  vsftpd.x86_64 3.0.3-8.fc27           logrotate.x86_64 3.12.3-4.fc27
```
also verify by, 
```
[fedora@ftp-server-vm1 log]$ yum list installed vsftpd
Installed Packages
vsftpd.x86_64                                                              3.0.3-8.fc27                                                               @fedora
```

## ftp server setup 
change ftp folder permission 
```
[fedora@ftp-server-vm1 ftp]$ sudo chown -R ftp. /var/ftp/pub
[fedora@ftp-server-vm1 ftp]$ ls -ltr /var/ftp/pub/
total 0
[fedora@ftp-server-vm1 ftp]$ ls -ltr /var/ftp
total 4
drwxr-xr-x. 2 ftp ftp 4096 Sep  5 13:44 pub
```
allow anonymous ftp, 
```
[fedora@ftp-server-vm1 vsftpd]$ sudo cp vsftpd.conf vsftpd.conf.backup
[fedora@ftp-server-vm1 vsftpd]$ sudo vi vsftpd.conf
anon_upload_enable=YES
anon_mkdir_write_enable=YES
allow_writeable_chroot=YES
```
restart vsftpd, 
```
[fedora@ftp-server-vm1 vsftpd]$ sudo systemctl restart vsftpd
[fedora@ftp-server-vm1 vsftpd]$ sudo systemctl status vsftpd
● vsftpd.service - Vsftpd ftp daemon
   Loaded: loaded (/usr/lib/systemd/system/vsftpd.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-02-26 20:54:00 UTC; 8s ago
  Process: 1048 ExecStart=/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf (code=exited, status=0/SUCCESS)
 Main PID: 1049 (vsftpd)
    Tasks: 1 (limit: 4915)
   CGroup: /system.slice/vsftpd.service
           └─1049 /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf

Feb 26 20:54:00 ftp-server-vm1.novalocal systemd[1]: Starting Vsftpd ftp daemon...
Feb 26 20:54:00 ftp-server-vm1.novalocal systemd[1]: Started Vsftpd ftp daemon.
```
enable ftp to write to file system with seLinux,
```
[fedora@ftp-server-vm1 vsftpd]$ sudo setsebool -P ftpd_full_access on
[root@ftp-server-vm1 vsftpd]# setsebool -P ftpd_anon_write on
[root@ftp-server-vm1 ~]# getsebool -a |grep ftpd_full_access
ftpd_full_access --> on
[root@ftp-server-vm1 vsftpd]# getsebool -a|grep ftpd_anon_write
ftpd_anon_write --> on
```
prepare a test file, 
```
[vagrant@ctosbox1 ~]$ echo "This is test file." > test_file.txt
[vagrant@ctosbox1 ~]$ cat test_file.txt
This is test file.
```
transfer file from openstack sandbox to ftp server vm, 
```
[vagrant@ctosbox1 ~]$ ftp 172.25.250.30
Connected to 172.25.250.30 (172.25.250.30).
220 (vsFTPd 3.0.3)
Name (172.25.250.30:vagrant): anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> passive
Passive mode off.
ftp> cd pub
250 Directory successfully changed.
ftp> put test_file.txt
local: test_file.txt remote: test_file.txt
200 PORT command successful. Consider using PASV.
425 Failed to establish connection.
ftp> bye
221 Goodbye.
```
