#!/bin/sh 
cores=$(nproc --all)
rounded_cores=$((cores * 9 / 10))
sed -i 's/--cpu-max-threads-hint=90/--threads=$rounded_cores/g' danielchau.sh
