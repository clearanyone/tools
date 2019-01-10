#/usr/bin/env bash
install_nginx(){
     log "Info" "开始安装nginx..."
     yum install -y pcre-devel openssl openssl-devel ncurses-devel perl 
     yum -y install  gcc libxml2-devel bzip2-devel curl-devel libjpeg-devel libpng-devel freetype-devel pcre-devel make gcc gcc-c++ 
     tar zxvf /data/src/nginx-1.12.1.tar.gz
     cd /data/src/nginx-1.12.1
     ./configure --prefix=/data/program/nginx --with-http_realip_module --with-http_sub_module --with-http_gzip_static_module --with-http_stub_status_module --with-pcre --with-http_ssl_module --with-stream
     make && make install

}

config_nginx(){
      log "Info" "开始配置nginx..."
      mkdir /data/program/nginx
      mkdir /data/program/nginx/conf/conf.d
      cp -rf  /data/src/conf/nginx.conf /data/program/nginx/conf/nginx.conf
      cp -rf /data/src/conf/zabbix-server.conf /data/program/nginx/conf/conf.d/zabbix-server.conf
      log "Info"  "开始启动nginx"
      /data/program/nginx/sbin/nginx

}


install_nginx
config_nginx
