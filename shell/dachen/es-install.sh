#!/bin/bash

install_es(){
    echo "开始安装ES"
    yum install -y unzip
	unzip /data/src/elasticsearch-rtf-2.x.zip -d /data/program/
	mv /data/program/elasticsearch-rtf-2.x /data/program/elasticsearch
	if  [[ ! -d /data/program/elasticsearch ]];then
	    echo "安装ES完成"	
	fi	
}

config_es(){
    echo "开始配置ES"
	echo "添加es用户"
	groupadd elastic
	useradd elastic -g elastic
	\cp /data/src/conf/elasticsearch.yml /data/program/elasticsearch/config/elasticsearch.yml
	cat>>/data/program/elasticsearch/start<<EOF
#!/bin/bash
su - elastic <<EOF
/data/program/elasticsearch/bin/elasticsearch -d;
sleep 5
exit 0;
EOF
    cat>>/data/program/elasticsearch/stop<<EOF	
#!/bin/bash
pid=`ps -ef|grep elasticsearch | grep elastic |grep -v grep |awk '{print $2}'`
kill -9 $pid
EOF
	chmod +x start stop
	chown -R elastic:elastic /data/program/elasticsearch
	echo "启动es"
	/data/program/elasticsearch/start
	
	
}

install_es
config_es
