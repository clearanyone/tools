grant all privileges on zabbix.* to zabbix@'127.0.0.1' identified by 'zabbix';
grant all privileges on zabbix.* to zabbix@'%' identified by 'zabbix';
grant all privileges on zabbix.* to zabbix@'localhost' identified by 'zabbix';  
flush privileges;
