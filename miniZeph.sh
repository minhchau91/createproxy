#!/bin/sh
wget --no-check-certificate -O xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz
tar -xvf xmrig.tar.gz
chmod +x ./xmrig-6.21.0/* 
read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
read -p "What is Worker? (exp: vps01): " worker
cat >>/root/danielchau.sh <<EOF
/xmrig-6.21.0/xmrig --donate-level 1 --cpu-max-threads-hint=90 --background -o $pool:5352 -u ZEPHYR3cXqeAwGfVsg9dQkiE9jTCUnJzv3sMbCEgjTDGAKaf8nyurWqX3sQFKoxrXrEW1yYYFF4dtF2wYvTByayxbrDLq3RP86w3z -p $worker -a rx/0 -k
EOF
chmod 777 /root/danielchau.sh

cat >>/var/spool/cron/root<<EOF
@reboot /root/danielchau.sh > /root/danielchau_log.txt
EOF
./danielchau.sh
