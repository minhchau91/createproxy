#!/bin/sh
pid=$(pidof xmrig)
sudo /bin/kill $pid
pid=$(pidof cpuminer-sse2)
sudo /bin/kill $pid2
