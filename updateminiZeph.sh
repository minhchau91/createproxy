#!/bin/sh
#worker=$(grep -oP '\-p\s+\K\S+' /root/danielchau.sh | cut -d' ' -f1)
read -p "What is Worker? (exp: vps01): " worker
#sudo apt-get update -y
#sudo apt-get install cpulimit -y
#wget --no-check-certificate -O xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz
#tar -xvf xmrig.tar.gz
#chmod +x ./xmrig-6.21.0/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 90))
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
sudo /root/xmrig-6.21.0/xmrig --donate-level 1 --threads=$cores --background -o $fastest_server:5352 -u ZEPHYR3cXqeAwGfVsg9dQkiE9jTCUnJzv3sMbCEgjTDGAKaf8nyurWqX3sQFKoxrXrEW1yYYFF4dtF2wYvTByayxbrDLq3RP86w3z -p $worker -a rx/0 -k
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh

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
./danielchau.sh