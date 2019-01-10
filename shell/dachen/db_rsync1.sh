#!/bin/bash
source /etc/profile
dst_path=/data2/www/crond
#rep
mongo_path=/data/backup/nfs/crond/mongodb
mongo_dbs=(health online-marketing auth2 activity)
logfile=/var/log/mysql_rsync.log
#dt=`date "+%Y-%m-%d"`
dt=`date "+%Y-%m-%d"`
rdt=`date -d '-7 days' +%Y-%m-%d`

#mongodb
for db in ${mongo_dbs[@]}
do
cd ${mongo_path}/${dt}
tar -zcvf - ${db} | openssl des3 -salt -k secretdachen | dd of=${dst_path}/mongodb/${db}_${dt}.tgz
if [ $? -eq 0 ];then
        echo "[`date "+%Y-%m-%d %H:%M:%S"`]   ${db} rsync success! file:${dst_path}/mongodb/${db}_${dt}.tgz" >> $logfile
else
        echo "[`date "+%Y-%m-%d %H:%M:%S"`]   ${db} rsync faild! file:`date "+%Y-%m-%d"`" >> $logfile
fi
done


find  ${dst_path} -name '*.tgz' -ctime +1  -exec rm -rf {} \;

