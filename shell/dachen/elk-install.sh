#!/bin/bash


install_elasticsearch(){
    echo "开始安装es 5.5.2"
	cd /data/src
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.tar.gz
	tar zxvf elasticsearch-5.5.2.tar.gz
	mv /data/src/elasticsearch-5.5.2 /data/program
	mv /data/program/elasticsearch-5.5.2 /data/program/elasticsearch
	if [[ ! -d /data/program/elasticsearch ]];then
	    echo "安装es完成"		
	fi	
}

install_logstash(){
    echo "开始安装logstash5.5.2"
	cd /data/src
    wget https://artifacts.elastic.co/downloads/logstash/logstash-5.5.2.tar.gz
	tar zxvf logstash-5.5.2.tar.gz
	mv logstash-5.5.2 /data/program
	mv /data/program/logstash-5.5.2 /data/program/logstash
	if [[ ! -d /data/program/logstash ]];then
	    echo "安装es完成"		
	fi
}	

install_kibana(){
    echo "开始安装kibana5.5.2"
	cd /data/src
    wget https://artifacts.elastic.co/downloads/kibana/kibana-5.5.2-linux-x86_64.tar.gz
	tar zxvf kibana-5.5.2-linux-x86_64.tar.gz
	mv /data/src/kibana-5.5.2-linux-x86_64 /data/program
	mv /data/program/kibana-5.5.2-linux-x86_64 /data/program/kibana
	if [[ ! -d /data/program/kibana ]];then
	    echo "安装kibana完成"		
	fi
}	


config_elasticsearch(){
    echo "开始配置es5.5.2"
	mv /data/program/elasticsearch/config/elasticsearch.yml elasticsearch.yml.old
	cat>/data/program/elasticsearch/config/elasticsearch.yml<<EOF
cluster.name: elk
path.data: /data/program/elasticsearch/data
path.logs: /data/program/elasticsearch/logs
http.port: 9200
EOF
    cat>/data/program/elasticsearch/start<<EOFG
#!/bin/bash
su - elastic <<EOF
/data/program/elasticsearch/bin/elasticsearch -d;
sleep 5
exit 0;
EOF
EOFG
    cat>/data/program/elasticsearch/start<<EOF
#!/bin/bash
pid=`ps -ef|grep elasticsearch | grep elastic |grep -v grep |awk '{print $2}'`
kill -9 $pid
EOF
    chmod +x start stop
    echo "添加用户elastic,配置目录权限"
	groupadd elastic
	useradd elastic -g elastic
	chown -R elastic:elastic /data/program/elasticsearch

}

config_kibana(){
    echo "开始配置kibana5.5.2"
	mv /data/program/kibana/config/kibana.yml kibana.yml.old
	cat>/data/program/kibana/config/kibana.yml<<EOF
server.port: 5601
server.host: "0.0.0.0"
server.maxPayloadBytes: 1048576
elasticsearch.url: "http://localhost:9200"
EOF
   cat>/data/program/kibana/start<<EOF
#!/bin/bash
nohup /data/program/kibana/bin/kibana >> /data/program/kibana/logs/kibana-logs.log &
EOF
   cat>/data/program/kibana/stop<<EOF
#!/bin/bash
p_count=`ps aux|grep kibana|grep -v grep |wc -l`
if [[ $p_count == "0" ]];then
        echo "服务本身就是停止的,无需其他操作!"

elif [[ $p_count == "1" ]];then
        ps aux|grep kibana|grep -v grep|awk '{printf $2}'|xargs kill -9
else
        pids=`ps -ef|grep kibana|grep -v grep |awk '{print $2}'`
        i=1
        while((1==1))
        do
                pid=`echo $pids|cut -d " " -f$i`
                if [ "$pid" != "" ]
                then
                        ((i++))
                        echo $pid  
                        kill -9 $pid
                else
                        break
                fi
        done
fi 
EOF
   chmod +x start stop


      
}

install_searchguard(){
    echo "安装es插件searchguard"
	/data/program/elasticsearch/bin/elasticsearch-plugin install -b com.floragunn:search-guard-5:5.5.2-15
    echo "安装kibana插件searchguard"  
    cd /data/src
    wget https://github.com/floragunncom/search-guard-kibana-plugin/releases/download/v5.5.2-4/searchguard-kibana-5.5.2-4.zip
    /data/program/kibana/bin/kibana-plugin install file:///data/src/searchguard-kibana-5.5.2-4.zip	
	echo "安装searchguard完成"
}

config_es_searchguard(){
    echo "生成key"
	cd /data/program/elasticsearch
	wget http://files.cnblogs.com/files/Orgliny/example-pki-scripts.tar.gz
	tar zxvf example-pki-scripts.tar.gz
	/data/program/elasticsearch/example-pki-scripts/example.sh
	cp /data/program/elasticsearch/example-pki-scripts/node-0-keystore.jks /data/program/elasticsearch/config/
    cp /data/program/elasticsearch/example-pki-scripts/truststore.jks /data/program/elasticsearch/config/
    nodekey=`cat /data/program/elasticsearch/example-pki-scripts/Readme.txt | grep "node-0 keystore password :"`
	nodekey=${key#*:}  #取得冒号后面的值
	Truststorekey=`cat /data/program/elasticsearch/example-pki-scripts/Readme.txt | grep "Truststore password:"`
	Truststorekey=${key#*:}
	echo "写入es配置"
	cat>>data/program/elasticsearch/config/elasticsearch.yml<<EOF
searchguard.ssl.transport.keystore_filepath: node-0-keystore.jks
searchguard.ssl.transport.keystore_password: ${nodekey}
searchguard.ssl.transport.truststore_filepath: truststore.jks
searchguard.ssl.transport.truststore_password: ${Truststorekey}
searchguard.ssl.transport.enforce_hostname_verification: false
searchguard.ssl.transport.resolve_hostname: false

searchguard.ssl.http.enabled: false
searchguard.ssl.http.keystore_filepath: node-0-keystore.jks
searchguard.ssl.http.keystore_password: ${nodekey}
searchguard.ssl.http.truststore_filepath: truststore.jks
searchguard.ssl.http.truststore_password: ${Truststorekey}

#searchguard.ssl.http.clientauth_mode: REQUIRE


searchguard.authcz.admin_dn:
 - CN=sgadmin,OU=client,O=client,L=test,C=DE	
EOF
    
   cp /data/program/elasticsearch/example-pki-scripts/sgadmin-keystore.jks /data/program/elasticsearch/plugins/search-guard-5/sgconfig
   chmod +x /data/program/elasticsearch/plugins/search-guard-5/sgconfig/tools/sgadmin.sh
   sgadminTruststorekey=`cat /data/program/elasticsearch/example-pki-scripts/Readme.txt | grep "sgadmin keystore password :"`
   sgadminTruststorekey=${key#*:}
   echo "生成SGadmin配置文件"
   /data/program/elasticsearch/plugins/search-guard-5/sgconfig/tools/sgadmin.sh -ts /data/program/elasticsearch/config/truststore.jks -tspass ${Truststorekey} -ks sgconfig/sgadmin-keystore.jks -kspass ${sgadminTruststorekey} -cd sgconfig/ -icl -nhnv -h 127.0.0.1
	
   echo "配置es_searchguard完成"
}

config_kibana_searchguard(){
    cp /data/program/elasticsearch/example-pki-scripts/kirk-signed.pem /data/program/kibana/config/ 
    cat>>/data/program/kibana/config/kibana.yml<<EOF
elasticsearch.username: "admin"
elasticsearch.password: "admin"
elasticsearch.ssl.ca: /data/program/kibana/config/kirk-signed.pem
elasticsearch.ssl.verify: false
EOF
    

}


start_elk(){
    echo "启动es"
	/data/program/elasticsearch/start
	p_count=`ps aux|grep elasticsearch|grep -v grep |wc -l`
    if [[ $p_count == "1" ]];then
        echo "启动es,成功"
	fi	
   echo "启动kibana"
	/data/program/kibana/start
	p_count=`ps aux|grep kibana|grep -v grep |wc -l`
    if [[ $p_count == "1" ]];then
        echo "启动kibana,成功"
	fi	

	
	
}




install_elasticsearch
install_logstash
install_kibana
config_elasticsearch
config_kibana
config_kibana
install_searchguard
config_es_searchguard
config_kibana_searchguard
start_elk
