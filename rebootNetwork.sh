#!/bin/sh
ulimit -n 65535
pid=$(/sbin/pidof 3proxy)
kill $pid
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
echo "Done"
