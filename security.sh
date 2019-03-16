#!/bin/sh
# desc: setup linux system security
# powered by www.lvtao.net
#account setup
passwd -l xfspasswd -l newspasswd -l nscdpasswd -l dbuspasswd -l vcsapasswd -l gamespasswd -l nobodypasswd -l avahipasswd -l haldaemonpasswd -l gopherpasswd -l ftppasswd -l mailnullpasswd -l pcappasswd -l mailpasswd -l shutdownpasswd -l haltpasswd -l uucppasswd -l operatorpasswd -l syncpasswd -l admpasswd -l lp
# 
chattr /etc/passwd /etc/shadowchattr +i /etc/passwdchattr +i /etc/shadowchattr +i /etc/groupchattr +i /etc/gshadow
# add continue input failure 3 ,passwd unlock time 5 minite
sed -i 's#auth required pam_env.so#auth required pam_env.sonauth required pam_tally.so onerr=fail deny=3 unlock_time=300nauth required /lib/security/$ISA/pam_tally.so onerr=fail deny=3 unlock_time=300#' /etc/pam.d/system-auth
# system timeout 5 minite auto logoutecho "TMOUT=300" >>/etc/profile
# will system save history command list to 10
sed -i "s/HISTSIZE=1000/HISTSIZE=10/" /etc/profile

# enable /etc/profile go!
source /etc/profile

# add syncookie enable /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
sysctl -p 

# exec sysctl.conf enable
# optimizer sshd_config
sed -i "s/#MaxAuthTries 6/MaxAuthTries 6/" /etc/ssh/sshd_config
sed -i "s/#Use yes/UseDNS no/" /etc/ssh/sshd_config
# limit chmod important commands
chmod 700 /bin/ping
chmod 700 /usr/bin/finger
chmod 700 /usr/bin/who
chmod 700 /usr/bin/wchmod 700 /usr/bin/locate
chmod 700 /usr/bin/whereis
chmod 700 /sbin/ifconfig
chmod 700 /usr/bin/pico
chmod 700 /bin/vi
chmod 700 /usr/bin/which
chmod 700 /usr/bin/gcc
chmod 700 /usr/bin/make
chmod 700 /bin/rpm

# history security
chattr +a /root/.bash_history
chattr +i /root/.bash_history

# write important command md5

cat > list <<EOF 
/bin/ping 
/bin/finger 
/usr/bin/who 
/usr/bin/w 
/usr/bin/locate 
/usr/bin/whereis 
/sbin/ifconfig 
/bin/pico 
/bin/vi 
/usr/bin/vim 
/usr/bin/which 
/usr/bin/gcc 
/usr/bin/make 
/bin/rpm 
EOF 

for i in `cat list` 
do 
	if [ ! -x $i ];then 
		echo "$i not found,no md5sum!" 
	else 
		md5sum $i >> /var/log/`hostname`.log
	fi
done
rm -f list





