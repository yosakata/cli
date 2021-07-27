#!/bin/bash
yum update -y
yum install -y httpd
echo `hostname -I | awk '{print $1}'` > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
