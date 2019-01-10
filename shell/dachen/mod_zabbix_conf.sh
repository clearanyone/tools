sed -i 's/# UnsafeUserParameters=0/UnsafeUserParameters=1/g' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
sed -i '1i Include=/data/program/zabbix_agentd/etc/zabbix_agentd.conf.d/*.conf' /data/program/zabbix_agentd/etc/zabbix_agentd.conf
/etc/init.d/zabbix_agentd restart
