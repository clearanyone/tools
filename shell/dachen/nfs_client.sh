#!/bin/bash
if [[ ! -d /data/backup ]];then
	mkdir /data/backup
fi

yum install nfs-utils autofs -y

cat >> /etc/auto.master <<EOF

/data/backup /etc/auto.nfs

EOF

cat > /etc/auto.nfs <<EOF
nfs     -rw     172.16.30.2:/data/backup
EOF

chkconfig autofs on
service autofs start

cd /data/backup/nfs
