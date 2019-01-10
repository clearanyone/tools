#!/bin/bash
cd /data/program/$1
#appport=`cat start |grep -oP '(?<=server.port=)\S+' |head -n 1 `
appport=`ps aux | grep $1.war | grep -v grep | grep -oP '(?<=server.port=)\S+' | head -n 1`
k2=`echo .\"$2\"`
appmetrics=`curl -s http://127.0.0.1:"$appport"/metrics | /usr/local/bin/jq "$k2"`
echo $appmetrics
