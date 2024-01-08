#!/bin/sh
pid=$(pidof xmrig)
sudo /bin/kill $pid
pid2=$(pidof cpuminer-sse2)
sudo /bin/kill $pid2
