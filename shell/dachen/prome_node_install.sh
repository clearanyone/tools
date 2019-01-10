#!/bin/bash
#
#date: 2018-05014
#by: wanglei

source /etc/profile

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
