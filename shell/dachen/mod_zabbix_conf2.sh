mv /data/program/zabbix_agentd/etc/zabbix_agentd.conf /data/program/zabbix_agentd/etc/zabbix_agentd.conf.bak
grep -v "^#" /data/program/zabbix_agentd/etc/zabbix_agentd.conf.bak |grep -v "^$" >> /data/program/zabbix_agentd/etc/zabbix_agentd.conf
/etc/init.d/zabbix_agentd restart
