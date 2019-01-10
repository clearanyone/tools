###### 1.yum ########
yum -y install gcc  libxml2-devel unixODBC-devel net-snmp-devel libcurl-devel libssh2-devel OpenIPMI-devel openssl-devel openldap-devel
sleep 5

###### 2.add user group #######
groupadd zabbix
useradd -g zabbix zabbix

####### 3.install #######
cd /data/src/
if [ ! -d zabbix-3.0.10 ] ;then
    tar -zxvf zabbix-3.0.10.tar.gz
fi
sleep 5

cd zabbix-3.0.10
./configure --enable-agent --prefix=/data/program/zabbix_agentd
sleep 5

make install
sleep 5

###### 4.modify config ######
ip_local=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

sed -i 's#Server=127.0.0.1#Server=172.16.30.1#g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i 's#ServerActive=127.0.0.1#ServerActive=172.16.30.1#g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i "s#Hostname=Zabbix server#Hostname=$ip_local#g" /data/program/zabbix_agentd/etc/zabbix_agentd.conf

####### 5. copy shell scripts ######
cp /data/src/zabbix-3.0.10/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/zabbix_agentd
sed -i 's#BASEDIR=/usr/local#BASEDIR=/data/program/zabbix_agentd#g' /etc/init.d/zabbix_agentd

####### 6. auto boot #######
chkconfig --add /etc/init.d/zabbix_agentd
chkconfig zabbix_agentd on
/etc/init.d/zabbix_agentd start
