#!/usr/bin/env bash
install_mariadb(){
	 cd /data/src
	 rm -rf /data/program/mysql
	 log "Info" "采用mariadb-10.1.26二进制包,解压mariadb..."
	 tar zxf mariadb-10.1.26-linux-glibc_214-x86_64.tar.gz -C /data/program/
	 log "Info" "移动到/data/program/mysql"
     mv  /data/program/mariadb-10.1.26-linux-glibc_214-x86_64  /data/program/mysql
	 
	 
}	

config_mariadb(){
     log "Info" "配置mysql lib链接"
	 echo '/data/program/mysql/lib' >> /etc/ld.so.conf
     ldconfig
     log "Info" "禁用transparent_hugepage"
     echo never > /sys/kernel/mm/transparent_hugepage/enabled
	 log "Info" "永久禁用transparent_hugepage"
	 mkdir /etc/tuned/no-thp
	 cat>/etc/tuned/no-thp/tuned.conf<<EOF
[main]
include=virtual-guest
[vm]
transparent_hugepages=never
EOF
     tuned-adm profile no-thp
     log "Info" "复制配置文件"
	 cd /data/program/mysql
	 cp /data/src/conf/my.cnf /data/program/mysql/my.cnf
     cp /data/src/conf/mysqld /data/program/mysql/mysqld
	 chmod +x /data/program/mysql/mysqld
	 log "Info" "删除多余的my.cnf文件"
	 if [ -f /etc/my.cnf ];then
	     rm -rf /etc/my.cnf
	 fi
	 log "Info" "添加用户"
	 mkdir /data/program/mysql/log
	 groupadd mysql
	 useradd -s /sbin/nologin -g mysql -M mysql
	 log "Info" "设置权限"   
	 chown -R mysql:mysql /data/program/mysql
	 log "Info" "初始化数据" 
     /data/program/mysql/scripts/mysql_install_db --basedir=/data/program/mysql --datadir=/data/program/mysql/data --user=mysql
     log "Info" "启动mysql" 
     /data/program/mysql/mysqld start
	 log "Info" "设定密码" 
     /data/program/mysql/bin/mysqladmin -u root password 'dachen@123'
     /data/program/mysql/bin/mysqladmin -u root -h localhost.localdomain password 'dachen@123'


}

install_mariadb
config_mariadb 
