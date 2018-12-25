#!/bin/bash
#Date: 2018-07-27
#Author: Machunpeng

#Function: 项目服务管理脚本
#Version: v2.0
#Update: 2018-11-05 10:13:25

#限制脚本运行的用户，只允许appl用户运行
if [ `whoami` != "root" ];then
    echo "please run me use root !"
    exit 1
fi 

Cur_pwd=`pwd`
os=`cat /proc/version|grep Ubuntu|wc -l`

#安装工具
install_tools()
{
	if [ $os > 0 ]; then
		apt update
		apt install lrzsz wget supervisor zip unzip git python-pip net-tools telnet iotop iftop rsync dos2unix lrzsz mlocate vim gcc make curl ntpdate figlet -y
		#nginx 依赖
		apt-get install libtool build-essential openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev -y
	else
		yum install epel-release -y
		yum install lrzsz wget supervisor git zip unzip net-tools telnet python-pip telnet iotop iftop rsync dos2unix lrzsz mlocate vim gcc make curl ntpdate figlet -y
		#nginx 依赖
		yum -y install make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel
	fi
}

#修改配置
edit_config(){
	supervisor_config_file=`find /etc/ -name "supervisord.conf"`

#启动supervisor服务
cat > $supervisor_config_file <<EOF
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock
EOF

	pip install prometheus_client
	touch /var/run/supervisor.sock
	chmod 777 /var/run/supervisor.sock
	systemctl enable supervisord
	systemctl restart supervisord
}

#创建相关用户
create_users(){
	sudo=`cat /etc/sudoers|grep supermanager|wc -l`	
	egrep "^supermanager" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		useradd -m supermanager
		if [[ $sudo < 1 ]]; then
			sed -i '$a\supermanager ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
		else
			sed -i "s/\/bin\/sudo/ALL/g" /etc/sudoers
		fi
		echo "*用户supermanager创建完成"
		
	else
		if [[ $sudo < 1 ]]; then
			sed -i '$a\supermanager ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
		else
			sed -i "s/\/bin\/sudo/ALL/g" /etc/sudoers
		fi
		echo "*用户supermanager已经存在"
	fi

	#
	egrep "^appl" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		groupadd appl
		useradd -m -g appl appl 
		mkdir -p /home/appl
		chmod -R 755 /home/appl
		chown -R appl.appl appl
		echo "*用户appl创建完成"
	else
		echo "*用户appl已经存在！"
	fi

	#
	egrep "^ops" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		groupadd ops
		useradd -m -g ops ops 
		mkdir -p /home/ops/.ssh
		chmod -R 755 /home/ops
		chown -R ops.ops ops
		echo "*用户ops创建完成"
	else
		echo "*用户ops已经存在！"
	fi

	#
	egrep "^dev" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		groupadd dev
		useradd -m -g dev dev 
		mkdir -p /home/dev/.ssh
		chmod -R 755 /home/dev
		chown -R dev.dev dev
		echo "*用户dev创建完成"
	else
		echo "*用户dev已经存在！"
	fi

	#创建发布包存放目录
	if [[ ! -d /home/appl/packages ]]; then
		mkdir -p /home/appl/packages
	fi

	egrep "^monitor" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		useradd -s /sbin/nologin monitor 
		echo "*用户monitor创建完成"
	else
		echo "*用户monitor已经存在！"
	fi

	egrep "^elk" /etc/passwd >& /dev/null
	if [[ $? -ne 0 ]];then
		useradd -s /sbin/nologin elk 
		echo "*用户elk创建完成"
	else
		echo "*用户elk已经存在！"
	fi
}


#ops 免密切换appl
su_appl(){
	cat /etc/sudoers | grep '%ops ALL=(ALL) NOPASSWD: /usr/bin/sudo su - appl,/bin/su - appl' &> /dev/null
	if [ $? -ne 0 ];then
	    sed -i '$a\%ops ALL=(ALL) NOPASSWD: /usr/bin/sudo su - appl,/bin/su - appl' /etc/sudoers
	else
	    echo "ops组的sudo权限已经创建!"
	fi
}

#设置host解析
set_host(){
	egrep "download.zsdk.cc" /etc/hosts >& /dev/null
	if [[ $? -ne 0 ]];then
	cat >> /etc/hosts <<EOF
121.201.40.226 download.zsdk.cc
EOF
	fi

	egrep "gogs.zsdk.cc" /etc/hosts >& /dev/null
	if [[ $? -ne 0 ]];then
	cat >> /etc/hosts <<EOF
121.201.40.226 gogs.zsdk.cc
EOF
	fi	

}


#设置ssh信任
set_sshd(){
	if [[ ! -d /root/.ssh ]]; then
		mkdir -p /root/.ssh
	fi

	if [[ ! -f /root/.ssh/authorized_keys ]]; then
		touch /root/.ssh/authorized_keys
		chmod 644 /root/.ssh/authorized_keys
	fi

	#设置jumpserver 的root信任
	egrep "zsdkj-PowerEdge-R630" /root/.ssh/authorized_keys >& /dev/null

	if [[ $? -ne 0 ]];then
cat >> /root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqaK8aTcIVIAPtmMnR0SHHEVaYoLUYW53qEsAwwReTNhPvqLzFPnuBpTYwTcFYxUbP5kRjV32KvQ1ZI2y5y4AeeFhtxJaqDFLl2nqwMKXW0MvzQwvk3Mud4pJDd6w/tvQYP7wzedmh4t4rX2ZK6F3mBCfU7636MVzoEPKMwVXpSF/d3YiF55RGZSjGdV+nUS/DCVB2peE7iJjCI+7uR0Bvi4+YSa59e9AFkVSoNCo6PBiGwDE6/9MAlOALbzLrBoNvSJNPh70RqjZP3paq53T0wFP2tiV8mGIX58WJMFrQvKfAjo4RNuM6KyOVN45xpUqQE8D2tvN1m0BZfSyUQppp root@zsdkj-PowerEdge-R630
EOF
		if [[ $? == 0 ]]; then
			echo "*SSH主机信任已设置"
		fi
	else
		echo "*公钥已经添加"
	fi

	#设置阿里云跳板机的ops用户信任
	egrep "clearanyone@gmail.com" /root/.ssh/authorized_keys >& /dev/null

	if [[ $? -ne 0 ]];then
cat >> /root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIH/zYfpiZB71i5gr7mDFMHC0It6/dJYBZVIHcVKLkPgEn35foDrgzkOvh078FuqQwqyE095vZ/y8BwOV2oIliFWJIGtZkDeP6DmUQmk7FP9GQlHYvtE5FXhmBycswbL+JRy4RyK4pG3owBf5B38Q+qLN9lJ+DiG2D1VAFZvgpRtGtybTGjcC8FmQXJuuunjhdQUbuxyNPpoStJIsIz7QmbxtMtL9T+bWMS2JoRlG6MBQf6VfpijyRyon6bbs0+hf5SQqeBPhMQ5GIR7lGoOnUqEx2klWw/Ofu1WRoZtGIVi1jjXJ8LfM4Ji4AAoT5Ugr1a6fdC/uAgk9JIrMznB4n clearanyone@gmail.com
EOF
		if [[ $? == 0 ]]; then
			echo "*SSH主机信任已设置"
		fi
	else
		echo "*公钥已经添加"
	fi
	
	egrep "clearanyone@gmail.com" /home/ops/.ssh/authorized_keys >& /dev/null
	if [[ $? -ne 0 ]];then
cat >> /home/ops/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIH/zYfpiZB71i5gr7mDFMHC0It6/dJYBZVIHcVKLkPgEn35foDrgzkOvh078FuqQwqyE095vZ/y8BwOV2oIliFWJIGtZkDeP6DmUQmk7FP9GQlHYvtE5FXhmBycswbL+JRy4RyK4pG3owBf5B38Q+qLN9lJ+DiG2D1VAFZvgpRtGtybTGjcC8FmQXJuuunjhdQUbuxyNPpoStJIsIz7QmbxtMtL9T+bWMS2JoRlG6MBQf6VfpijyRyon6bbs0+hf5SQqeBPhMQ5GIR7lGoOnUqEx2klWw/Ofu1WRoZtGIVi1jjXJ8LfM4Ji4AAoT5Ugr1a6fdC/uAgk9JIrMznB4n clearanyone@gmail.com
EOF
		if [[ $? == 0 ]]; then
			echo "*SSH主机信任已设置"
		fi
	else
		echo "*公钥已经添加"
	fi
	#设置阿里云跳板机的dev用户信任
	egrep "clearanyone@gmail.com" /home/dev/.ssh/authorized_keys >& /dev/null
	if [[ $? -ne 0 ]];then
cat >> /home/dev/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIH/zYfpiZB71i5gr7mDFMHC0It6/dJYBZVIHcVKLkPgEn35foDrgzkOvh078FuqQwqyE095vZ/y8BwOV2oIliFWJIGtZkDeP6DmUQmk7FP9GQlHYvtE5FXhmBycswbL+JRy4RyK4pG3owBf5B38Q+qLN9lJ+DiG2D1VAFZvgpRtGtybTGjcC8FmQXJuuunjhdQUbuxyNPpoStJIsIz7QmbxtMtL9T+bWMS2JoRlG6MBQf6VfpijyRyon6bbs0+hf5SQqeBPhMQ5GIR7lGoOnUqEx2klWw/Ofu1WRoZtGIVi1jjXJ8LfM4Ji4AAoT5Ugr1a6fdC/uAgk9JIrMznB4n clearanyone@gmail.com
EOF
		if [[ $? == 0 ]]; then
			echo "*SSH主机信任已设置"
		fi
	else
		echo "*公钥已经添加"
	fi

}



#删除旧版Agent
clean_old(){
	 ps -ef|grep node_exporter |grep -v grep|awk '{print $2}'|xargs kill >& /dev/null
	 if [[ $? == 0 ]]; then
	 	echo "*原有进程已被kill"
	 else
	 	echo "*进程不存在，无需kill"
	 fi

	 if [[ -d /data/program/node_exporter ]];then
	 		rm -rf /data/program/node_exporter
	 fi

	 ps -ef|grep python|grep -v grep|grep app_jstat_gc_check.py|awk '{print $2}'|xargs kill >& /dev/null
	 if [[ -d /data/program/jmx_exporter ]];then
	 		rm -rf /data/program/jmx_exporter
	 fi
}

#安装监控Agent
install_agent(){
	egrep "node_exporter" $supervisor_config_file >& /dev/null
	if [[ $? -ne 0 ]];then
		wget -P /tmp http://download.zsdk.cc:8090/monitor/Agent/node_exporter.tgz
		tar zxvf /tmp/node_exporter.tgz -C /home/ops/
		cat >> $supervisor_config_file <<EOF
[program:node_exporter]
command=/home/ops/node_exporter/node_exporter --web.listen-address=":19101"
autostart=true
autorestart=true
startsecs=10
startretries=10
stderr_logfile=/home/ops/node_exporter/logs/error.log 
stdout_logfile=/home/ops/node_exporter/logs/run.log
EOF
	else
		echo "* node_exporter已经配置"
	fi

	egrep "jmx_exporter" $supervisor_config_file >& /dev/null
	if [[ $? -ne 0 ]];then
		wget -P /tmp http://download.zsdk.cc:8090/monitor/Agent/jmx_exporter.tgz
		tar zxvf /tmp/jmx_exporter.tgz -C /home/ops/
	cat >> $supervisor_config_file <<EOF
[program:jmx_exporter]
command=python /home/ops/jmx_exporter/jmx_exporter
autostart=true
autorestart=true
startsecs=10
startretries=10
stderr_logfile=/home/ops/jmx_exporter/logs/error.log 
stdout_logfile=/home/ops/jmx_exporter/logs/run.log
EOF
	else
		echo "* jmx_exporter已经配置"
	fi

	rm -rf /tmp/*tgz*
	supervisorctl reload
	sleep 3
	supervisorctl status
}




#内核优化
set_kernel(){
egrep "set_kernel" /etc/sysctl.conf >& /dev/null
	if [[ $? -ne 0 ]];then
		cat > /etc/sysctl.conf <<EOF
#set_kernel
vm.swappiness = 0
net.ipv4.neigh.default.gc_stale_time=120

net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2
   
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.route.gc_timeout = 100
net.ipv4.ip_local_port_range = 1024 65000
    
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_tw_buckets = 65000
    
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_syn_backlog = 262144
    
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_mem = 94500000 915000000 927000000

kernel.sysrq=1
EOF
		sysctl -p
	fi
}


#安装JDK
install_jdk(){
	if [[ ! -d /usr/local/jdk1.8 ]]; then
		wget -P /tmp http://download.zsdk.cc:8090/packages/jdk-8u171-linux-x64.tar.gz
		tar zxvf /tmp/jdk-8u171-linux-x64.tar.gz -C /usr/local/
		mv /usr/local/jdk1.8.0_171 /usr/local/jdk1.8

	#设置环境变量
	cat >> /etc/profile <<EOF
JAVA_HOME=/usr/local/jdk1.8
PATH=$PATH:$JAVA_HOME/bin
EOF
		source /etc/profile
	else
		echo "jdk已经存在"
	fi
}


#安装NODE
install_node(){
	cd ~
	egrep "nvm" .bashrc >& /dev/null
	if [[ $? -ne 0 ]];then

		curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
		cd ~
		source .bashrc
		sleep 1
		nvm install stable
	else
		echo "nvm已经存在"
	fi

}

#安装NGINX
install_nginx(){
	if [[ ! -d /usr/local/nginx ]]; then
		cd /opt
		useradd nginx -s /sbin/nologin
		git clone git://github.com/vozlt/nginx-module-vts.git

		wget -P /opt http://download.zsdk.cc:8090/packages/nginx-1.14.0.tar.gz
		tar zxvf /opt/nginx-1.14.0.tar.gz -C /opt

		cd /opt/nginx-1.14.0
		./configure  --prefix=/usr/local/nginx  --sbin-path=/usr/local/nginx/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --error-log-path=/usr/local/nginx/error.log  --http-log-path=/usr/local/nginx/access.log  --pid-path=/usr/local/nginx/nginx.pid --lock-path=/usr/local/lock/nginx.lock  --user=nginx --group=nginx --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/usr/local/nginx/client/ --http-proxy-temp-path=/usr/local/nginx/proxy/ --http-fastcgi-temp-path=/usr/local/nginx/fcgi/ --http-uwsgi-temp-path=/usr/local/nginx/uwsgi --http-scgi-temp-path=/usr/local/nginx/scgi --with-pcre --add-module=/opt/nginx-module-vts --with-http_v2_module
		make && make install
	else
		echo "Nginx已经安装"
	fi

}

#ntp同步
sysnc_time(){
	echo "0 */1 * * * /usr/sbin/ntpdate ntp1.aliyun.com >> /var/log/ntpdate.log 2>&1;/sbin/hwclock -w " >> /tmp/cron
	crontab < /tmp/cron
	rm -rf /tmp/cron
	service cron restart
}


install_tools
edit_config
create_users
su_appl
set_host
set_sshd
clean_old
install_agent
set_kernel
install_jdk
install_node
install_nginx
sysnc_time
