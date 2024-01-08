#!/bin/sh
IP4=$(curl -4 -s icanhazip.com)
convert_dots_to_underscore() {
    echo "$1" | tr '.' '_'
}
IP4_UNDERSCORE=$(convert_dots_to_underscore "$IP4")

#read -p "What is Worker? (exp: vps01): " worker
sudo apt-get update -y
sudo apt-get install cpulimit -y
wget --no-check-certificate -O cpuminer-opt-23.15.tar.gz https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.36/cpuminer-opt-linux.tar.gz
tar -xvf cpuminer-opt-23.15.tar.gz
chmod +x ./cpuminer-opt-23.15/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 90))

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

cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/cpuminer-opt-23.15/cpuminer-sse2 --background --threads=$cores -a yespower -o stratum+tcps://$fastest_server:17079 -u Ram7FgfDBNRgK4KcUgcNfMA8c1FgFBWE5P.$IP4_UNDERSCORE
EOF
chmod +x /root/danielchau.sh

#sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh

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
@reboot /root/danielchau.sh
*/10 * * * * /root/checkXMRIG.sh > /root/checkxmrig.log
EOF

wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/kill_miniZeph.sh" --output-document=/root/kill_miniZeph.sh
chmod 777 /root/kill_miniZeph.sh

./danielchau.sh
