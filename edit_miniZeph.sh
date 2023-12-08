#!/bin/sh
sudo apt-get update -y
sudo apt-get install cpulimit -y
cores=$(nproc --all)
echo "Cores: $cores"
rounded_cores=$((cores * 9 / 10))
echo "rounded_cores: $rounded_cores"
limitCPU=$((cores * 90))
echo "limitCPU: $limitCPU"

sed -i "s|--threads=$rounded_cores|--threads=$cores|g" danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh
