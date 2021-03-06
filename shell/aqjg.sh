#!/bin/bash

#脚本运行前备份所有涉及到的文件，共17个

cp /etc/login.defs /etc/login.defs.bak

cp /etc/security/limits.conf /etc/security/limits.conf.bak

cp /etc/profile /etc/profile.bak

cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak

cp /etc/inittab /etc/inittab.bak

cp /etc/motd /etc/motd.bak

cp /etc/xinetd.conf /etc/xinetd.conf.bak

cp /etc/group /etc/group.bak

cp /etc/shadow /etc/shadow.bak

cp /etc/services /etc/services.bak

cp /etc/security /etc/security.bak

cp /etc/passwd /etc/passwd.bak

cp /etc/grub.conf /etc/grub.conf.bak

cp /boot/grub/grub.conf /boot/grub/grub.conf.bak

cp /etc/lilo.conf /etc/lilo.conf.bak

cp /etc/ssh_banner /etc/ssh_banner.bak

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

cp /etc/aliases /etc/aliases.bak

#############################################################################

#修复设置口令更改最小间隔天数

MINDAY=`cat -n /etc/login.defs | grep -v ".*#.*" | grep PASS_MIN_DAYS | awk '{print $1}'`

sed -i ''$MINDAY's/.*PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs

#############################################################################

#修复设置口令过期前警告天数

WARNDAY=`cat -n /etc/login.defs | grep -v ".*#.*" | grep PASS_WARN_AGE | awk '{print $1}'`

sed -i ''$WARNDAY's/.*PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

#############################################################################

#修复系统core dump设置

HARD=`cat /etc/security/limits.conf | grep "hard core"`

if [ -z "$HARD" ]

then

echo "* hard core 0" >>/etc/security/limits.conf

else

sed -i 's/.*hard core.*/* hard core 0'/g /etc/security/limits.conf

fi

SOFT=`cat /etc/security/limits.conf | grep "soft core"`

if [ -z "$SOFT" ]

then

echo "* soft core 0" >>/etc/security/limits.conf

else

sed -i 's/.*soft core.*/* soft core 0'/g /etc/security/limits.conf

fi

##############################################################################

##修复历史命令设置

#sed -i 's/.*HISTSIZE=.*/HISTSIZE=5'/g /etc/profile

###############################################################################

#修复密码重复使用次数限制

REMEMBER=`cat -n /etc/pam.d/system-auth | grep -v ".*#.*" | grep "password sufficient pam_unix.so" | awk '{print $1}'`

sed -i ''$REMEMBER's/$/ &remember=5/' /etc/pam.d/system-auth

###############################################################################

#修复是否设置口令生存周期

MAXDAY=`cat -n /etc/login.defs | grep -v ".*#.*" | grep PASS_MAX_DAYS | awk '{print $1}'`

sed -i ''$MAXDAY's/.*PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs

###############################################################################

#修复口令最小长度

MINLEN=`cat -n /etc/login.defs | grep -v ".*#.*" | grep PASS_MIN_LEN | awk '{print $1}'`

sed -i ''$MINLEN's/.*PASS_MIN_LEN.*/PASS_MIN_LEN 8/' /etc/login.defs

#################################################################################

#修复是否设置命令行界面超时退出

TMOUT=`cat /etc/profile | grep "export TMOUT="`

if [ -z "$TMOUT" ]

then

echo "export TMOUT=600" >>/etc/profile

else

sed -i 's/.*export TMOUT=.*/export TMOUT=600'/g /etc/profile

fi

##################################################################################

#修复系统是否禁用ctrl+alt+del组合键

CTRL=`cat /etc/inittab | grep "ca::ctrlaltdel"`

if [ -n "$CTRL" ]

then

LINE=`cat -n /etc/inittab | grep -v ".*#.*" | grep "ca::ctrlaltdel" | awk '{print $1}'`

sed -i ''$LINE's/^/&#/' /etc/inittab

fi

###################################################################################

#修复设备密码复杂度策略

sed -i 's/.*pam_cracklib.*/password requisite pam_cracklib.so difok=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1'/g /etc/pam.d/system-auth

###################################################################################

#修复设置ssh成功登录后Banner

if [ -f /etc/motd ]

then

echo "Login success. All activity will be monitored and reported " > /etc/motd

else

touch /etc/motd

echo "Login success. All activity will be monitored and reported " > /etc/motd

fi

####################################################################################

#修复用户umask设置

ACTUAL=`umask`

policy=0027

if [ "$ACTUAL" != "$policy" ]

then

echo "umask 027" >>/etc/profile

fi

#####################################################################################

#修复重要目录或文件权限设置

chmod 600 /etc/xinetd.conf

chmod 644 /etc/group

chmod 400 /etc/shadow

chmod 644 /etc/services

chmod 600 /etc/security

chmod 644 /etc/passwd

chmod 600 /etc/grub.conf

chmod 600 /boot/grub/grub.conf

chmod 600 /etc/lilo.conf

#####################################################################################

#修复设置ssh登录前警告Banner

if [ -f /etc/ssh_banner ]

then

chown bin:bin /etc/ssh_banner

else

touch /etc/ssh_banner

chown bin:bin /etc/ssh_banner

fi

chmod 644 /etc/ssh_banner

echo " Authorized only. All activity will be monitored and reported " > /etc/ssh_banner

sed -i 's/.*Banner.*/Banner \/etc\/ssh_banner'/g /etc/ssh/sshd_config

#######################################################################################

##修复禁止root用户远程登录

#ROOT=`cat /etc/ssh/sshd_config | grep -v "^#" | grep PermitRootLogin`

#if [ -z "$ROOT" ]

#then

#echo "PermitRootLogin no" >>/etc/ssh/sshd_config

#else

#LINEROOT=`cat -n /etc/ssh/sshd_config | grep -v ".*#.*" | grep PermitRootLogin | awk '{print $1}'`

#sed -i ''$LINEROOT's/.*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

#fi

#修复已修改系统banner信息

mv /etc/issue.net /etc/issue.net.bak

mv /etc/issue /etc/issue.bak

## 别名文件更改修复

sed -i 's/games/#games/g' /etc/aliases

sed -i 's/games/#system/g' /etc/aliases

sed -i 's/games/#uucp/g' /etc/aliases

sed -i 's/games/#dumper/g' /etc/aliases

sed -i 's/games/#decode/g' /etc/aliases

sed -i 's/games/#ingres/g' /etc/aliases

sed -i 's/games/#toor/g' /etc/aliases

sed -i 's/games/#manager/g' /etc/aliases

sed -i 's/games/#operator/g' /etc/aliases

#hosts.allow 和 hosts.deny 限制配置修复

echo "sshd:192.168.0.0/255.255.0.0 172.21.0.0/255.255.0.0 10.0.0.0/255.0.0.0" >>/etc/hosts.allow

echo "sshd:all" >>/etc/hosts.deny

#core dump 配置安全修改

#echo "ulimit -S -c unlimited">>/etc/profile

#log 日至文件权限修改

if [ -f /etc/syslog.conf ]

then

LOGDIR=`cat /etc/syslog.conf | grep -v "^[ ]*#"|sed '/^#/d' |sed '/^$/d' |awk '(($2!~/@/) && ($2!~/*/) && ($2!~/-/)) {print $2}'`

chmod 600 $LOGDIR

fi

if [ -f /etc/rsyslog.conf ]

then

LOGDIR=`cat /etc/rsyslog.conf | grep -v "^[ ]*#"|sed '/^#/d' |sed '/^$/d' |awk '(($2!~/@/) && ($2!~/*/) && ($2!~/-/)) {print $2}'`

chmod 600 $LOGDIR

fi

###############################################################################################################

for i in daemon bin sys adm lp uucp nuucp smmsp games ftp mail sync shutdown halt news operator gopher nobody

do

sed -i s/''$i':.:'/''$i':!!:'/g 2.txt

done
