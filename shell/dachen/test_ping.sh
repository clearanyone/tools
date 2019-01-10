#!/bin/bash
#

for((i=17;i<=24;i++));
do
    ip=172.16.10.$i
    test_ping=`ping -c 1 -w 1 $ip | grep loss | awk '{print $6}' | awk -F "%" '{print $1}'`
    if [ $test_ping -eq 100 ]
    then
        echo -e "\033[31m$ip is fail \033[0m"
    else
        echo "$ip is ok"
    fi
done
