#!/bin/sh

/bin/pkill -f '/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg'
systemctl restart network
systemctl start NetworkManager.service
/sbin/ifup eth0

rm -fv /etc/rc2.local

cat >>/etc/rc2.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup eth0
bash /home/proxy-installer/boot_ifconfig.sh
ulimit -n 65535
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF
chmod +x /etc/rc2.local
bash /etc/rc2.local
