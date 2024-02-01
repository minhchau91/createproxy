#!/bin/sh
#read -p "What is Worker? (exp: vps01): " worker
#IP4=$(curl -4 -s icanhazip.com)
rm -fv danielchau.sh
sudo apt-get update -y
sudo apt-get install cpulimit -y
wget --no-check-certificate -O xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz
tar -xvf xmrig.tar.gz
chmod +x ./xmrig-6.21.0/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 80))

#find best servers
servers=("stratum-eu.rplant.xyz" "stratum-asia.rplant.xyz" "stratum-na.rplant.xyz")
fastest_server=""
min_latency=999999
for server in "${servers[@]}"; do
    latency=$(ping -c 2 $server | awk '/^rtt/ { print $4 }' | cut -d '/' -f 2)
    if (( $(echo "$latency < $min_latency" | bc -l) )); then
        min_latency=$latency
        fastest_server=$server
    fi
done
echo "$fastest_server with min_latency is: $latency"


cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/xmrig-6.21.0/xmrig --background --threads=$cores -a ghostrider --url randomx.rplant.xyz:17110 --tls --user dQwRbzRghkWYB9MPj4PdX7Rt5uF4SZtfES.Linode --pass m=solo
sleep 4
EOF
chmod +x /root/danielchau.sh

#sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh

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
if pgrep xmrig >/dev/null
then
  echo "xmrig is running."
else
  echo "xmrig isn't running"
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
sleep 4
./danielchau.sh
