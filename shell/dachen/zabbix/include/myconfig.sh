#!/usr/bin/env bash
myconfig(){
    log "Info" "安装依赖"
    yum -y install  gcc libxml2-devel bzip2-devel curl-devel libjpeg-devel libpng-devel freetype-devel pcre-devel make gcc gcc-c++ pcre-devel openssl openssl-devel ncurses-devel perl
    log "Info" "禁用firewalld"
    systemctl disable firewalld
    log "Info" "配置/etc/profile"
    cat>>/etc/profile<<EOF
#MYSQL HOME
MYSQL_HOME=/data/program/mysql

#PHP_HOME
PHP_HOME=/data/program/php

#NGINX_HOME
NGINX_HOME=/data/program/nginx

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/lib64/erlang/bin:\$JAVA_HOME/bin:\$MYSQL_HOME/bin:\$PHP_HOME/bin:\$NGINX_HOME/sbin
EOF
    source /etc/profile
    log "Info" "创建目录" 
    mkdir /data/program
    mkdir /data/program/php
    mkdir /data/program/nginx
    mkdir /data/program/zabbix-server
}

myconfig