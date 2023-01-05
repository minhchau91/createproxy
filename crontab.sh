#!/bin/sh
cat /dev/null > /var/spool/cron/root
cat >>/var/spool/cron/root<<EOF
# 40mins-interval
#0,40 0-22/2 * * * /root/Rotation.sh > /root/Rotation_log.txt
#20 1-23/2 * * * /root/Rotation.sh > /root/Rotation_log.txt
59 7 * * * /root/Rotation.sh > /root/Rotation_log.txt
EOF
