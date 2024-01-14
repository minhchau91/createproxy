#!/bin/sh
IP4=$(curl -4 -s icanhazip.com)
convert_dots_to_underscore() {
    echo "$1" | tr '.' '_'
}
IP4_UNDERSCORE=$(convert_dots_to_underscore "$IP4")
rm -fR /root/cpuminer-opt-linux
#read -p "What is Worker? (exp: vps01): " worker
sudo apt-get update -y
sudo apt-get install cpulimit -y
wget --no-check-certificate -O cpuminer-opt-linux.tar.gz https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.36/cpuminer-opt-linux.tar.gz
mkdir /root/cpuminer-opt-linux
tar -xvf cpuminer-opt-linux.tar.gz -C /root/cpuminer-opt-linux
chmod +x ./cpuminer-opt-linux/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 80))

cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/cpuminer-opt-linux/cpuminer-sse2 --background --threads=$cores -a yespower -o stratum+tcps://stratum-eu.rplant.xyz:17079 -u v3K4mds92oWPHSPuQ4Tm6bSSNMCmNj1JyY.Vultr
sleep 2
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof cpuminer-sse2) > /dev/null 2>&1 &" danielchau.sh

cat /dev/null > /etc/rc.local
cp /root/danielchau.sh /etc/rc.local
chmod +x /etc/rc.local

cat /dev/null > /etc/systemd/system/rc-local.service

cat >>/etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local Support
ConditionPathExists=/etc/rc.local

[Service]
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target 
EOF


cat /dev/null > /root/checkXMRIG.sh
cat >>/root/checkXMRIG.sh <<EOF
#!/bin/bash
if pgrep cpuminer-sse2 >/dev/null
then
  echo "cpuminer-sse2 is running."
else
  echo "cpuminer-sse2 isn't running"
  bash kill_miniZeph.sh
  bash danielchau.sh
fi
EOF
chmod +x /root/checkXMRIG.sh

cat /dev/null > /var/spool/cron/crontabs/root
cat >>/var/spool/cron/crontabs/root<<EOF
*/10 * * * * /root/checkXMRIG.sh > /root/checkxmrig.log
EOF

wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/kill_miniZeph.sh" --output-document=/root/kill_miniZeph.sh
chmod 777 /root/kill_miniZeph.sh
./kill_miniZeph.sh
sleep 3
./danielchau.sh
