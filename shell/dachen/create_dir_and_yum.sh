#! /bin/bash
cd /data
mkdir src program temp

yum install -y gcc gcc-c++ vim-enhanced wget lrzsz net-tools ntp curl tree curl-devel zip unzip autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel \
libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel \
openssl openssh openssl-devel nss_ldap openldap openldap-devel openldap-clients openldap-servers libxslt-devel libevent-devel  libtool-ltdl bison libtool  python  lsof iptraf \
strace kernel-devel kernel-headers pam-devel Tcl/Tk  cmake  ncurses-devel bison setuptool
