#!/bin/sh
mv /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/bk-ifcfg-eth0
cp /etc/sysconfig/network-scripts/ifcfg-eth1 /etc/sysconfig/network-scripts/bk-ifcfg-eth1
sed -i 's/static/none/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/IPV6INIT="no"/IPV6INIT="yes"/g' /etc/sysconfig/network-scripts/ifcfg-eth1
read -p "What is your ipv6 address /126?: " IPV6ADDR
read -p "What is your ipv6 default gateway?: " IPV6_DEFAULTGW
cat >>/etc/sysconfig/network-scripts/ifcfg-eth1<<EOF
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
PREFIX="31"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6_AUTOCONF="no"
IPV6ADDR="$IPV6ADDR/126"
IPV6_DEFAULTGW="$IPV6_DEFAULTGW"
DNS2="2001:4860:4860::8888"
DNS3="2001:4860:4860::8844"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="System eth1"
EOF
