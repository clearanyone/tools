#!/bin/bash
#
# date:2018-05-09
# by:wanglei

######   1.add user Ops   ######
#groupadd Ops
#useradd -g Ops Ops

######   2.modify sudoers  ######
if [[ -f /etc/sudoers.bak ]]
then
    mv /etc/sudoers.bak /etc/sudoers.bak.old
    cp /etc/sudoers /etc/sudoers.bak
else
    cp /etc/sudoers /etc/sudoers.bak
fi

sed -i '/match_group_by_gid/d' /etc/sudoers

cat >> /etc/sudoers <<EOF
zabbix ALL = NOPASSWD: SUDO
zabbix ALL = NOPASSWD:/data/program/jdk8/bin/jstat
zabbix ALL = NOPASSWD:/bin/sed
zabbix ALL = NOPASSWD:/bin/cat
zabbix ALL = NOPASSWD:/bin/awk
zabbix ALL=(root) NOPASSWD:/bin/sed
EOF
