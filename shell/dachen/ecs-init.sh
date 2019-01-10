#!/bin/bash
#
# date: 2018-05-14
# by: wanglei

# 为了方便脚本使用，在初始化系统前，先将相关脚本、软件包拷贝到待初始化服务器/tmp目录下


source /etc/profile

##########  1.初始化硬盘并挂载到/data目录  ##########
if [[ ! -d /data ]];then
        mkdir /data
fi

fdisk /dev/vdb >>/tmp/ecs-init.log <<EOF
n
p
1


w
EOF

mke2fs -t ext4 /dev/vdb1 >>/tmp/ecs-init.log
sed -i '$a\/dev/vdb1       /data   ext4    defaults        1 1' /etc/fstab
mount -a >>/tmp/ecs-init.log

echo "硬盘初始化完成。" | tee -a /tmp/ecs-init.log

##########  2.在/data目录下创建相关文件目录  #########
mkdir -p /data/{src,program,temp}

echo "目录创建完成。" | tee -a /tmp/ecs-init.log

##########  3.将/tmp目录下软件包移动到/data/src目录下  ##########
cp /tmp/*.gz /data/src/

echo "软件包拷贝完成。" | tee -a /tmp/ecs-init.log

##########  4.安装相关依赖软件包  #########
yum makecache >>/tmp/ecs-init.log
yum install -y gcc gcc-c++ vim-enhanced wget lrzsz net-tools ntp curl tree curl-devel zip unzip autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel \
libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel \
openssl openssh openssl-devel nss_ldap openldap openldap-devel openldap-clients openldap-servers libxslt-devel libevent-devel  libtool-ltdl bison libtool  python  lsof \
iptraf strace kernel-devel kernel-headers pam-devel Tcl/Tk  cmake  ncurses-devel bison setuptool unixODBC-devel net-snmp-devel libcurl-devel libssh2-devel OpenIPMI-devel \
 >>/tmp/ecs-init.log

echo "软件包依赖安装完成。" | tee -a /tmp/ecs-init.log

##########  5.安装JDK并配置JAVA环境变量  ##########
cd /data/src
tar -zxf /data/src/jdk-8u144-linux-x64.tar.gz -C /data/src/
mv /data/src/jdk1.8.0_144 /data/program/jdk
cat >> /etc/profile.d/java.sh <<EOF
export JAVA_HOME=/data/program/jdk
export PATH=\$PATH:\$JAVA_HOME/bin
EOF

source /etc/profile.d/java.sh

echo "JDK安装配置完成。" | tee -a /tmp/ecs-init.log

##########  6.安装zabbix  ##########
groupadd zabbix
useradd -g zabbix zabbix
sleep 1

cd /data/src
if [ ! -d zabbix-3.0.10 ] ;then
    tar -zxf zabbix-3.0.10.tar.gz
fi
sleep 5

cd zabbix-3.0.10
./configure --enable-agent --prefix=/data/program/zabbix_agentd  >>/tmp/ecs-init.log
sleep 5

make install >>/tmp/ecs-init.log
sleep 5

ip_local=`/sbin/ifconfig -a | grep -w 'inet' | grep -v '127.0.0.1' | awk '{print $2}'`
sed -i 's#Server=127.0.0.1#Server=172.16.30.1#g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i 's#ServerActive=127.0.0.1#ServerActive=172.16.30.1#g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i "s#Hostname=Zabbix server#Hostname=$ip_local#g" /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i 's/# UnsafeUserParameters=0/UnsafeUserParameters=1/g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i '1i Include=/data/program/zabbix_agentd/etc/zabbix_agentd.conf.d/*.conf' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
mv /data/program/zabbix_agentd/etc/zabbix_agentd.conf /data/program/zabbix_agentd/etc/zabbix_agentd.conf.bak
grep -v "^#" /data/program/zabbix_agentd/etc/zabbix_agentd.conf.bak |grep -v "^$" >> /data/program/zabbix_agentd/etc/zabbix_agentd.conf

cp /data/src/zabbix-3.0.10/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/zabbix_agentd
sed -i 's#BASEDIR=/usr/local#BASEDIR=/data/program/zabbix_agentd#g' /etc/init.d/zabbix_agentd

chkconfig --add /etc/init.d/zabbix_agentd
chkconfig zabbix_agentd on

echo "zabbix安装配置完成。" | tee -a /tmp/ecs-init.log

##########  7.添加zabbix用户sudo权限  ##########
if [[ -f /etc/sudoers.bak ]]
then
    mv /etc/sudoers.bak /etc/sudoers.bak.old
    cp /etc/sudoers /etc/sudoers.bak
else
    cp /etc/sudoers /etc/sudoers.bak
fi

sed -i '/match_group_by_gid/d' /etc/sudoers

cat >> /etc/sudoers <<EOF
zabbix ALL = NOPASSWD: SUDO
zabbix ALL = NOPASSWD:/data/program/jdk8/bin/jstat
zabbix ALL = NOPASSWD:/bin/sed
zabbix ALL = NOPASSWD:/bin/cat
zabbix ALL = NOPASSWD:/bin/awk
zabbix ALL=(root) NOPASSWD:/bin/sed
EOF

echo "zabbix用户sudo权限添加完成。" | tee -a /tmp/ecs-init.log

##########  8.安装Prometheus客户端  ##########
groupadd prometheus
useradd -g prometheus prometheus
sleep 1
cd /data/src
tar xf node_exporter-0.15.2.linux-amd64.tar.gz
sleep 1
mv /data/src/node_exporter-0.15.2.linux-amd64 /data/program/node_exporter
chown -R prometheus.prometheus /data/program/node_exporter/
sleep 1
su - prometheus -c "nohup /data/program/node_exporter/node_exporter >/dev/null 2>&1 &"


echo "Prometheus客户端安装完成。" | tee -a /tmp/ecs-init.log
echo "系统初始化完成。" | tee -a /tmp/ecs-init.log
