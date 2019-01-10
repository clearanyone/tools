#!/bin/bash
projects=`ls /data/program | grep -v jdk8 | grep -v zabbix_agentd`
for project in ${projects[@]} 
do
    sh /data/program/$project/stop
done

