#!/bin/bash
yum update -y
#yum install -y httpd24 php70 mysql56-server php70-mysqlnd
yum install httpd -y
#cp -p /var/www/noindex/index.html /var/www/html/index.html
echo "DR Environment" >  /var/www/html/index.html
service httpd start
service httpd enable
