#!/bin/sh
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
