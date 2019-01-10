#!/bin/sh
list_file=$1
src_file=$2
dest_file=$3
cat $list_file | while read line
do
   host_ip=`echo $line | awk '{print $1}'`
   username=`echo $line | awk '{print $2}'`
   password=`echo $line | awk '{print $3}'`
   echo "$host_ip"
   ./expect_scp $host_ip $username $password $src_file $dest_file
done 
