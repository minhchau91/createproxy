#!/bin/sh
pid=$(pidof xmrig)
sudo /bin/kill $pid
pid2=$(pidof cpuminer-sse2)
sudo /bin/kill $pid2
pid3=$(pidof gpupool_miner_worker_2023_09_13_04_ubuntu16.04)
sudo /bin/kill $pid3
pid4=$(pidof hacash_miner_pool_worker_2022_09_09_01)
sudo /bin/kill $pid4
pid5=$(pidof bms)
sudo /bin/kill $pid5
