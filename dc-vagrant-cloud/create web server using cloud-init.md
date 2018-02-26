# create web server using cloud-init

## openstack sandbox 
Follow up the [setup guide](https://github.com/robertluwang/cloud-hands-on-guide/blob/master/dc-vagrant-cloud/One%20Node%20one%20NIC%20Openstack%20Sandbox(centos)%20Setup%20Guide.md).

## create web server instance using cloud-init
web-server-vm1, fedora, m2.small,
```
#!/bin/bash
echo "This is web server test using cloud-init" > /etc/motd

yum -y install httpd mariadb-server

systemctl start httpd.service
systemctl start mariadb.service
systemctl enable httpd.service

echo "Web server successfully installed." > /var/www/html/index.html
```

## ssh to web server 
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ ssh -i /home/vagrant/.ssh/lab-key.pem fedora@172.25.250.32
This is web server test using cloud-init
```
from /etc/motd, can see cloud-init performed.

vm Internet access ok,
```
[fedora@web-server-vm1 ~]$ ping google.ca
PING google.ca (172.217.9.131) 56(84) bytes of data.
64 bytes from dfw25s26-in-f3.1e100.net (172.217.9.131): icmp_seq=1 ttl=47 time=45.3 ms
64 bytes from dfw25s26-in-f3.1e100.net (172.217.9.131): icmp_seq=2 ttl=47 time=42.8 ms
```
## check cloud init log
```
[fedora@web-server-vm1 log]$ less  /var/log/cloud-init-output.log
```
httpd and mariadb service running well,
```
[fedora@web-server-vm1 log]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-02-26 22:33:08 UTC; 16min ago
     Docs: man:httpd.service(8)
 Main PID: 3344 (httpd)
   Status: "Total requests: 0; Idle/Busy workers 100/0;Requests/sec: 0; Bytes served/sec:   0 B/sec"
    Tasks: 213 (limit: 4915)
   CGroup: /system.slice/httpd.service
           ├─3344 /usr/sbin/httpd -DFOREGROUND
           ├─3345 /usr/sbin/httpd -DFOREGROUND
           ├─3346 /usr/sbin/httpd -DFOREGROUND
           ├─3348 /usr/sbin/httpd -DFOREGROUND
           └─3349 /usr/sbin/httpd -DFOREGROUND

Feb 26 22:33:06 web-server-vm1.novalocal systemd[1]: Starting The Apache HTTP Server...
Feb 26 22:33:08 web-server-vm1.novalocal systemd[1]: Started The Apache HTTP Server.
[fedora@web-server-vm1 log]$ systemctl status mariadb
● mariadb.service - MariaDB 10.2 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2018-02-26 22:33:22 UTC; 16min ago
 Main PID: 3707 (mysqld)
   Status: "Taking your SQL requests now..."
    Tasks: 35 (limit: 4915)
   CGroup: /system.slice/mariadb.service
           └─3707 /usr/libexec/mysqld --basedir=/usr

Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: To do so, start the server, then issue the following commands:
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: '/usr/bin/mysqladmin' -u root password 'new-password'
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: '/usr/bin/mysqladmin' -u root -h web-server-vm1.novalocal password 'new-password'
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: Alternatively you can run:
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: '/usr/bin/mysql_secure_installation'
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: which will also give you the option of removing the test
Feb 26 22:33:19 web-server-vm1.novalocal mysql-prepare-db-dir[3585]: databases and anonymous user created by default.  This is
Feb 26 22:33:20 web-server-vm1.novalocal mysqld[3707]: 2018-02-26 22:33:20 139970793471232 [Note] /usr/libexec/mysqld (mysqld 10.2.12-MariaDB) starting as pr
Feb 26 22:33:20 web-server-vm1.novalocal mysqld[3707]: 2018-02-26 22:33:20 139970793471232 [Warning] Changed limits: max_open_files: 1024  max_connections: 1
Feb 26 22:33:22 web-server-vm1.novalocal systemd[1]: Started MariaDB 10.2 database server.
```

## verify web server 
from openstack sandbox, can verify the web server,
```
[vagrant@ctosbox1 ~(keystone_lab_user)]$ curl http://172.25.250.32
Web server successfully installed.
```








