#!/bin/bash

if [[ ! -d /data ]];then
	mkdir /data
fi

fdisk /dev/vdb<<EOF
n
p
1


w
EOF

mke2fs -t ext4 /dev/vdb1
sed -i '$a\/dev/vdb1       /data   ext4    defaults        1 1' /etc/fstab
mount -a
