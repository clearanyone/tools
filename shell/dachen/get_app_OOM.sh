#!/bin/bash
cd /data/program/$1
appport=`ps aux | grep $1.war | grep -v grep | grep -oP '(?<=server.port=)\S+' | head -n 1`
if [ `tail -1000 /data/program/$1/$1_"$appport".log | grep OutOfMemory | wc -l` -ne 0 ];then
     echo "1"
else
     echo "0"	 	 
fi
