#!/bin/sh

ulimit -n 65535
/bin/pkill -f '/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg'
sleep 5

echo "rebootNetwork"

WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
WORKDATA2="${WORKDIR}/ipv6-subnet.txt"

IP4=$(curl -4 -s icanhazip.com)
IP6=$(awk -F "|" '{print $1}' ${WORKDATA2})
Prefix=$(awk -F "|" '{print $2}' ${WORKDATA2})
User=$(awk -F "|" '{print $3}' ${WORKDATA2})
Pass=$(awk -F "|" '{print $4}' ${WORKDATA2})
interface=$(awk -F "|" '{print $5}' ${WORKDATA2})
Auth=$(awk -F "|" '{print $6}' ${WORKDATA2})
#FIRST_PORT=$(awk -F "|" '{print $7}' ${WORKDATA2})
#LAST_PORT=$(awk -F "|" '{print $7}' ${WORKDATA2})
FIRST_PORT=30000
LAST_PORT=30499

systemctl restart network
systemctl start NetworkManager.service
/sbin/ifup ${interface}
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"

chmod +x $WORKDIR/boot_*.sh /etc/rc.local

rm -fv /etc/rc.local

cat >>/etc/rc.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup ${interface}
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 65535
/bin/pkill -f '/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg'
sleep 5
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF
chmod +x /etc/rc.local
bash /etc/rc.local
echo "Reboot Network Done"
