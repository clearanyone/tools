#! /bin/bash
date_bf3=`date -d "-3days" +"%Y%m%d"`
dir_tty=/data/program/jumpserver/logs/tty
dir_tty_bak=/data2/backup2/jumpserver/tty

if [ -d $dir_tty/$date_bf3 ]; then
    mv $dir_tty/$date_bf3 $dir_tty_bak	
    if [ $? -eq 0 ]; then
	date_now=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$date_now mv $dir_tty/$date_bf3 succuss" >> /var/log/jumpserver_tty_bak.log
    else
	date_now=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$date_now mv $dir_tty/$date_bf3 -------------------- fail!!!" >> /var/log/jumpserver_tty_bak.log	
    fi

else
    echo "$dir_tty/$date_bf3 ----------------- not exist!!!" >> /var/log/jumpserver_tty_bak.log

fi
