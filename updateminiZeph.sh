#!/bin/sh
cat /dev/null > /var/spool/cron/crontabs/root
cat >>/var/spool/cron/crontabs/root<<EOF
*/5 * * * * /root/checkXMRIG.sh > /root/checkxmrig.log
EOF
