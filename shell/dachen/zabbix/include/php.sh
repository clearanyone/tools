#!/usr/bin/env bash
install_php(){
     log "Info" "安装编译支持"
     yum -y install  gcc libxml2-devel bzip2-devel curl-devel libjpeg-devel libpng-devel freetype-devel

     tar -zxvf /data/src/php-5.6.30.tar.gz
     cd /data/src/php-5.6.30
     mkdir /data/program/php
     log "Info" "开始编译..."
     /data/src/php-5.6.30/configure --prefix=/data/program/php \
--with-config-file-path=/data/program/php/etc/ --with-bz2 --with-curl \
--enable-ftp --enable-sockets --disable-ipv6 --with-gd \
--with-jpeg-dir=/usr/local --with-png-dir=/usr/local \
--with-freetype-dir=/usr/local --enable-gd-native-ttf \
--with-iconv-dir=/usr/local --enable-mbstring --enable-calendar \
--with-gettext --with-libxml-dir=/usr/local --with-zlib \
--with-mysql-sock=/tmp/mysql.sock \
--with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql=mysqlnd \
--enable-dom --enable-xml --enable-fpm --with-libdir=lib64 --enable-bcmath
      log "Info" "安装开始..."
      make && make install

}


config_php(){

    log "Info" "复制配置文本"
    cp /data/src/conf/php.ini /data/program/php/etc/php.ini
    cp /data/src/conf/php-fpm.conf /data/program/php/etc/php-fpm.conf

    log "Info" "配置自启动"

     \cp -r -a /data/src/php-5.6.30/sapi/fpm/init.d.php-fpm  /etc/init.d/php-fpm56
     chmod +x /etc/init.d/php-fpm56
     chkconfig --add php-fpm56
     service php-fpm56 start   #启动php-fpm


}



install_php
config_php
