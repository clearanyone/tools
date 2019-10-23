#!/bin/bash
#by payne.bai
#2018-3-15 10:32:32
#安装和自动创建虚拟用户
###############################
#定义变量
SYS_FTP_USER="ftpuser"
YUM="yum install -y"
VSFTPD_SOFT="vsftpd*"
VSFTP_VUSER="pam*  libdb-utils  libdb*  --skip-broken"
VSFTP_DIR="/etc/vsftpd"
VSFTPD_CONF="$VSFTP_DIR/vsftpd.conf"
VSFTPD_FTPUSERS="$VSFTP_DIR/ftpusers.txt"
VSFTPD_VSFTPD_LOGIN_DB="/etc/vsftpd/vsftpd_login.db"
VSFTPD_PAM="/etc/pam.d/vsftpd"
VSFTPD_USER_CONF_DIR="/etc/vsftpd/vsftpd_user_conf"
VSFTPD_USER_FILE_DIR="/data/$SYS_FTP_USER"
###############################
#VSFTPD安装配置
function Install_VSFTPD () {
    $YUM $VSFTPD_SOFT
    mv $VSFTPD_CONF $VSFTPD_CONF.bak
    cat >> $VSFTPD_CONF << EOF
anonymous_enable=YES
local_enable=YES
chroot_local_user=YES
#chroot_list_enable=YES
#chroot_list_file=/etc/vsftpd/chroot_list
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
userlist_enable=YES
tcp_wrappers=YES
#config virtual user FTP
pam_service_name=vsftpd
guest_enable=YES
guest_username=ftpuser
user_config_dir=$VSFTPD_USER_CONF_DIR
virtual_use_local_privs=YES
allow_writeable_chroot=YES
EOF
init_vuser_env
}
###################################
#初始化虚拟用户环境
function init_vuser_env () {
    echo -e "\033[32m正在正在安装PAM及libdb-utils！\033[0m"
    $YUM $VSFTP_VUSER
    rpm -qa | grep pam &>/dev/null 2>&1
    if [ $? -eq 0 ];then
        echo -e "\033[32mPAM安装成功！\033[0m"
    else
        echo -e "\033[32mPAM未安装成功！\033[0m"
    fi
    rpm -qa | grep libdb-utils &>/dev/null 2>&1
    if [ $? -eq 0 ];then
        echo -e "\033[32mlibdb-utils安装成功！\033[0m"
    else
        echo -e "\033[32mlibdb-utils未安装成功！\033[0m"
    fi
    echo -e "\033[32m正在修改$VSFTPD_PAM文件！\033[0m"
    mv $VSFTPD_PAM $VSFTPD_PAM.bak
    cat >> $VSFTPD_PAM << EOF
auth      required        /lib64/security/pam_userdb.so   db=/etc/vsftpd/vsftpd_login
account   required        /lib64/security/pam_userdb.so   db=/etc/vsftpd/vsftpd_login
EOF
    echo -e "\033[32m创建非login系统用户$SYS_FTP_USER！\033[0m"
    useradd -s /sbin/nologin $SYS_FTP_USER
    mkdir -p $VSFTPD_USER_CONF_DIR
}
###################################
#创建VSFTPD虚拟用户
function Create_Vusers () {
    if [ ! -f $VSFTPD_FTPUSERS ];then
        touch $VSFTPD_FTPUSERS
    else
        echo -e "\033[32m以下是现有用户用户名！\033[0m"
        cat $VSFTPD_FTPUSERS
    fi
    sleep 1
    read -p "请输入新的虚拟用户用户名（多个以空格分隔）：" Vuser_name
    
    VUSER_NAME=($(echo $Vuser_name))
        i=0
        while [[ $i < ${#VUSER_NAME[@]} ]]
        do
            USER_NU=$(grep "${VUSER_NAME[i]}" $VSFTPD_FTPUSERS | wc -l)
            if [ $USER_NU -eq 0 ];then
                echo "${VUSER_NAME[i]}" >> $VSFTPD_FTPUSERS
                read -p "请输入${VUSER_NAME[i]}虚拟用户密码：" Vuser_passwd
                if [ ! -n "$Vuser_passwd" ];then
                    echo -e "\033[32m密码为空，请重新输入！\033[0m"
                else
                    echo "$Vuser_passwd" >> $VSFTPD_FTPUSERS
                    echo -e "\033[32m密码写入成功！\033[0m"
                    echo -e "\033[32m开始创建用户${VUSER_NAME[i]}的个人配置文件以及目录！\033[0m"
                    mkdir -p $VSFTPD_USER_FILE_DIR/${VUSER_NAME[i]}
                    cat >> $VSFTPD_USER_CONF_DIR/${VUSER_NAME[i]} << EOF
local_root=$VSFTPD_USER_FILE_DIR/${VUSER_NAME[i]}
write_enable=YES
EOF
                fi
            else
                echo -e "\033[32m此用户已存在，请重新创建！\033[0m"
            fi
        let "i++"
        done
        read -p "请确认是否写入虚拟用户数据库（Y/N）！" YN
        if [ $YN == Y -o $YN == y -o $YN == yes ];then
            db_load -T -t hash -f $VSFTPD_FTPUSERS $VSFTPD_VSFTPD_LOGIN_DB
            chmod  700  $VSFTPD_VSFTPD_LOGIN_DB
        else
            echo -e "\033[32m刚创建的虚拟用户未写入数据库，3s后退出！\033[0m"
            sleep 3
            exit
        fi
    chown ftpuser:ftpuser /data -R
}
###############################
#设置菜单栏
PS3="请选择所需服务："
select i in Install_VSFTPD Create_Vusers Start_VSFTPD Restart_VSFTPD QUIT
do
case $i in
        Install_VSFTPD)
                Install_VSFTPD
        ;;
        Create_Vusers)
                Create_Vusers
        ;;
        Start_VSFTPD)
                service vsftpd start;systemctl enabled vsftpd
        ;;
        Restart_VSFTPD)
                service vsftpd restart
        ;;
        QUIT)
                exit
        ;;
        *)
        echo "Usage: $0 {1|2|3|4}"
esac
done
