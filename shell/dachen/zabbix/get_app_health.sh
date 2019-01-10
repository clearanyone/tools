#!/bin/bash 

if [ ! -f /tmp/$1_building ];then
    if [ $1 ] &&  [ -d /data/program/$1 ];then
       cd /data/program/$1
       appport=`cat start |grep -oP '(?<=server.port=)\S+' |head -n 1 `
       httpcode=`curl -o /dev/null -s -w %{http_code} http://127.0.0.1:$appport/health`
    fi

    if [[ $httpcode == "200" ]];then 
       echo "1"
    else
       echo "0"
    fi
else
    echo "1" 
fi
