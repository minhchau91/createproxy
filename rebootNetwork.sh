#!/bin/sh

systemctl restart network
sleep 2
rm -fv /etc/rc2.local
cat >>/etc/rc2.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup eth0
bash /home/proxy-installer/boot_ifconfig.sh
ulimit -n 65535
EOF
chmod +x /etc/rc2.local
bash /etc/rc2.local
