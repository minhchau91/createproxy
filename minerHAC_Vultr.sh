#!/bin/sh
IP4=$(curl -4 -s icanhazip.com)
convert_dots_to_underscore() {
    echo "$1" | tr '.' '_'
}
IP4_UNDERSCORE=$(convert_dots_to_underscore "$IP4")
rm -fR /root/HAC
#read -p "What is Worker? (exp: vps01): " worker
sudo apt-get update -y
sudo apt-get install cpulimit -y
wget --no-check-certificate -O HAC.zip https://www.hacash.diamonds/pool/gpu.zip
mkdir /root/HAC
unzip -xvf HAC.zip -C /root/HAC
chmod +x ./HAC/* 
cores=$(nproc --all)
#rounded_cores=$((cores * 9 / 10))
#read -p "What is pool? (exp: fr-zephyr.miningocean.org): " pool
limitCPU=$((cores * 80))

cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/HAC/gpupool_miner_worker_2023_09_13_04_ubuntu22.04
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof gpupool_miner_worker_2023_09_13_04_ubuntu22.04) > /dev/null 2>&1 &" danielchau.sh

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

cat /dev/null > /root/HAC/minerworker.config.ini
cat >>/root/HAC/minerworker.config.ini <<EOF

rewards = 1CKAk1hoaLHMjErLJNoYgaoAnHRJKBKK7x

detail_log = true


;; for CPU ;;
supervene = $cores

;; for GPU ;;
gpu_enable = false
gpu_opencl_path = ./root/HAC/x16rs_opencl
;gpu_group_size = 32
;gpu_group_concurrent = 32
;gpu_item_loop = 32
;gpu_span_time = 5.0 ; seconds
;gpu_platform_match = 

EOF

cat /dev/null > /root/checkXMRIG.sh
cat >>/root/checkXMRIG.sh <<EOF
#!/bin/bash
if pgrep gpupool_miner_worker_2023_09_13_04_ubuntu22.04 >/dev/null
then
  echo "gpupool_miner_worker_2023_09_13_04_ubuntu22.04 is running."
else
  echo "gpupool_miner_worker_2023_09_13_04_ubuntu22.04 isn't running"
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
