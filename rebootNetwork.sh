#!/bin/sh

sysctl -w net.ipv6.conf.eth0.accept_dad=0
systemctl restart network
ifup eth0
bash /home/proxy-installer/boot_ifconfig.sh
