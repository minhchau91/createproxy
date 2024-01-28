#!/bin/sh
wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/kill_miniZeph.sh" --output-document=/root/kill_miniZeph.sh
chmod 777 /root/kill_miniZeph.sh
./kill_miniZeph.sh
sleep 4
rm -fv kill_miniZeph.sh
rm -fv checkXMRIG.sh
rm -fv cpuminer-opt-linux.tar.gz
rm -fv danielchau.sh
rm -fR cpuminer-opt-linux
