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


cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/xmrig-6.21.0/xmrig --donate-level 1 --threads=$cores --background -o nlm.2realminers.com:4445 -u Na1QYaudZ8aHZfAQQy9uT4NieN7ejUGHYhqnSJCHfiwbj4ZQPJy7cQB9sqttfx8pVX5JrkourUKA7MECVKgVp7it6dM251zTz4 -p Vultr -a rx/0 -k
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh

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

./danielchau.sh
