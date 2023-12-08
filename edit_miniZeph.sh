#!/bin/sh 
cores=$(nproc --all)
echo "Cores: $cores" 
rounded_cores=$((cores * 9 / 10))
echo "rounded_cores: $rounded_cores" 
limitCPU=$((cores * 90))
echo "limitCPU: $limitCPU" 
xmrigpid=$(pidof xmrig)
sed -i 's/--cpu-max-threads-hint=${rounded_cores}/--threads=${cores}/g' danielchau.sh
#sed -i -e 'cpulimit --limit=${limitCPU} --pid ${xmrigpid}  > /dev/null 2>&1 &' danielchau.sh
