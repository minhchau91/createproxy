#!/bin/sh
cat /dev/null > /var/spool/cron/root
cat >>/var/spool/cron/root<<EOF
#1
*/40 0,*/2 * * * /root/Rotation.sh > /root/Rotation_log.txt
#2
*/20 1,*/2 * * * /root/Rotation.sh > /root/Rotation_log.txt
#3
0 2,*/2 * * * /root/Rotation.sh > /root/Rotation_log.txt
EOF
