#!/bin/sh 
cores=$(nproc --all)
echo "Cores: $cores" 
rounded_cores=$((cores * 9 / 10))
echo "rounded_cores: $rounded_cores" 
sed -i 's/--cpu-max-threads-hint=90/--threads=${rounded_cores}/g' danielchau.sh
