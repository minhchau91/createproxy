#!/bin/sh
read -p "What is Worker? (exp: vps01): " worker
#wget --no-check-certificate -O xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz
#tar -xvf xmrig.tar.gz
chmod +x ./xmrig-6.21.0/* 
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
#find best servers
servers=("fr-zephyr.miningocean.org" "de-zephyr.miningocean.org" "ca-zephyr.miningocean.org" "us-zephyr.miningocean.org" "hk-zephyr.miningocean.org" "sg-zephyr.miningocean.org")
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
sudo /root/xmrig-6.21.0/xmrig --donate-level 1 --threads=6 --background -o $fastest_server:5352 -u ZEPHYR3cXqeAwGfVsg9dQkiE9jTCUnJzv3sMbCEgjTDGAKaf8nyurWqX3sQFKoxrXrEW1yYYFF4dtF2wYvTByayxbrDLq3RP86w3z -p $worker -a rx/0 -k
EOF
chmod +x /root/danielchau.sh

cat /dev/null > /var/spool/cron/crontabs/root
cat >>/var/spool/cron/crontabs/root<<EOF
@reboot /root/danielchau.sh*
EOF

wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/kill_miniZeph.sh" --output-document=/root/kill_miniZeph.sh
chmod 777 /root/kill_miniZeph.sh

./danielchau.sh
