#!/bin/bash
zbx_sender='/data/program/zabbix_agentd/bin/zabbix_sender'
zbx_cfg='/data/program/zabbix_agentd/etc/zabbix_agentd.conf'
zbx_tmp_today='/tmp/.today_zabbix_jmx_status'
zbx_tmp_yesterday='/tmp/.yesterday_zabbix_jmx_status'

sudo /bin/sed -i 's/jstatToday/jstatYesterday/g'  /tmp/.yesterday_zabbix_jmx_status
sudo /bin/sed -i 's/jstat/jstatToday/g'  /tmp/.today_zabbix_jmx_status

$zbx_sender -c $zbx_cfg -i $zbx_tmp_today
$zbx_sender -c $zbx_cfg -i $zbx_tmp_yesterday
