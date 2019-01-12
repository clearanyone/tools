#!/bin/bash
path=`pwd`
function read_dir(){
    for file in `ls $1`
    do
        if [[ -d $1"/"$file ]];then 
        	echo $1"/"$file
            read_dir $1"/"$file
        else
            #echo $1"/"$file
            if [[ $file == "config-prod.properties" ]];then
            	sed -i '' 's/job.zsdkj.com/job.zsdk.cc/g' $1"/"$file
            fi
        fi
    done
}
read_dir $path