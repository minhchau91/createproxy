#!/bin/sh
cat /dev/null > /var/spool/cron/root
cat >>/var/spool/cron/root<<EOF
# 40mins-interval
40 0 * * * /root/Rotation.sh > /root/Rotation_log.txt       (0)
0,40 2-22/2 * * * /root/Rotation.sh > /root/Rotation_log.txt(2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22)
20 1-23/2 * * * /root/Rotation.sh > /root/Rotation_log.txt  (1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23)
EOF
