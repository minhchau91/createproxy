#!/bin/bash

servers=("fr-zephyr.miningocean.org" "de-zephyr.miningocean.org" "ca-zephyr.miningocean.org" "us-zephyr.miningocean.org" "hk-zephyr.miningocean.org" "sg-zephyr.miningocean.org")
fastest_server=""
min_latency=999999

for server in "${servers[@]}"; do
    latency=$(ping -c 2 $server | awk '/^rtt/ { print $4 }' | cut -d '/' -f 2)
    echo "$server with $latency"
    if (( $(echo "$latency < $min_latency" | bc -l) )); then
        min_latency=$latency
        fastest_server=$server
    fi
done

echo "fastest_server: $fastest_server"

sed -E -i "s/(-o[[:space:]]+)[^:[:space:]]+:[0-9]+/\1$fastest_server:5352/" /root/danielchau.sh
