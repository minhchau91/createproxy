#!/bin/sh
pid=$(pidof xmrig)
sudo /bin/kill $pid
pid2=$(pidof cpuminer-sse2)
sudo /bin/kill $pid2
pid3=$(pidof gpupool_miner_worker_2023_09_13_04_ubuntu22.04)
sudo /bin/kill $pid3
