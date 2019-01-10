#!/bin/bash

for i in {1..254}

do

HOST=192.168.20.$i           

ping -c 2 $HOST &>/dev/null

if [ $? -eq 0 ];then

echo "$HOST is up" >> ip.txt

fi

done
