#!/bin/bash

export http_proxy='http://proxy_auth:czSVLUk5@192.168.25.111:8080/' && export https_proxy='http://proxy_auth:czSVLUk5@192.168.25.111:8080/'

#install epel-release
yum install -y epel-release
#install nginx
yum install -y nginx
#change nginx port
sed -ie 's/:80/:4881/g' /etc/nginx/nginx.conf
sed -i 's/listen 80;/listen 4881;/' /etc/nginx/nginx.conf
#disable SELinux
#setenforce 0
#start nginx
systemctl start nginx
systemctl status nginx
#check nginx port
ss -tlpn | grep 4881