#!/usr/bin/env bash

install_zabbix(){
     log "Info" "开始安装zabbix..."
     yum install -y net-snmp-devel java-devel mysql-devel
     tar zxvf /data/src/zabbix-3.0.10.tar.gz
     cd /data/src/zabbix-3.0.10
     /data/src/zabbix-3.0.10/configure --prefix=/data/program/zabbix-server --enable-server --with-mysql --with-net-snmp --with-libcurl --with-libxml2 --enable-agent --enable-java
     make install

}


config_zabbix(){
     log "Info" "建立zabbix数据库..."
     /data/program/mysql/bin/mysql -e "CREATE DATABASE zabbix DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;" -pdachen@123
     /data/program/mysql/bin/mysql -e "GRANT ALL ON zabbix.* TO 'zabbix'@'%' IDENTIFIED BY 'zabbix';" -pdachen@123
	  log "Info" "开始配置zabbix..."
     /data/program/mysql/bin/mysql -u root -pdachen@123 -D zabbix < /data/src/conf/schema.sql
     /data/program/mysql/bin/mysql -u root -pdachen@123 -D zabbix < /data/src/conf/images.sql
     /data/program/mysql/bin/mysql -u root -pdachen@123 -D zabbix < /data/src/conf/data.sql

     cp /data/src/conf/zabbix_server.conf /data/program/zabbix-server/etc/zabbix_server.conf
     /data/program/mysql/bin/mysql -u root -pdachen@123 -D zabbix < /data/src/conf/zabbix.sql

	 log "Info" "添加前端"
	 mkdir /data/www
     mkdir /data/www/html
	 cp -rf /data/src/zabbix-3.0.10/frontends/php /data/www/html/zabbix-server
	 log "Info" "添加用户"
	 groupadd zabbix
	 useradd -s /sbin/nologin -g zabbix -M zabbix
	 log "Info" "设置权限"   
	 chown -R zabbix:zabbix /data/program/zabbix-server
     log "Info" "启动zabbix-server"	 
     /data/program/zabbix-server/sbin/zabbix_server


}

install_zabbix
config_zabbix
