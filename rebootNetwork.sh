#!/bin/sh

sysctl -w net.ipv6.conf.eth0.accept_dad=0
systemctl restart network
cat >>/etc/rc2.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup eth0
bash /home/proxy-installer/boot_ifconfig.sh
ulimit -n 65535
EOF
chmod +x /etc/rc2.local
bash /etc/rc2.local
