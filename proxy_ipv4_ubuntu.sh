#!/bin/sh
install_3proxy() {
    echo "installing 3proxy"
    mkdir -p /3proxy
    cd /3proxy
    URL="https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz"
    wget -qO- $URL | tar -xzvf-
    cd 3proxy-0.9.3
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    mv /3proxy/3proxy-0.9.3/bin/3proxy /usr/local/etc/3proxy/bin/
    wget https://raw.githubusercontent.com/minhchau91/Proxy_ipv6/main/3proxy.service-Centos8 --output-document=/3proxy/3proxy-0.9.3/scripts/3proxy.service2
    cp /3proxy/3proxy-0.9.3/scripts/3proxy.service2 /usr/lib/systemd/system/3proxy.service
    systemctl link /usr/lib/systemd/system/3proxy.service
    systemctl daemon-reload
#    systemctl enable 3proxy
    echo "* hard nofile 999999" >>  /etc/security/limits.conf
    echo "* soft nofile 999999" >>  /etc/security/limits.conf
    echo "net.ipv6.conf.${interface}.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
    sysctl -p
    systemctl stop ufw
    systemctl disable ufw

    cd $WORKDIR
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 3000
nserver 1.1.1.1
nserver 1.0.0.1
nserver 2606:4700:4700::64
nserver 2606:4700:4700::6400
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456 
flush
auth $Auth
users $(awk -F "|" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})
$(awk -F "|" '{print "auth " $3"\n" \
"allow " $1 "\n" \
"proxy -4 -n -a -p" $6 " -i" $5 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$User|$Pass|$Auth|$interface|$IP4|$port"
    done
}

gen_iptables() {
    cat <<EOF
    $(awk -F "|" '{print "iptables -I INPUT -p tcp --dport " $6 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}


sysctl -w net.ipv6.conf.eth0.accept_dad=0
apt-get update -y
apt-get install network-manager -y
apt-get install net-tools wget -y
apt-get install -y gcc net-tools zip make curl tar >/dev/null
sudo apt-get -y install shc

echo "installing apps"

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
echo "Detected your ipv4: $IP4" 


interface=eth0
Auth=none
User=mcproxy
Pass=mcproxy092023
FIRST_PORT=20001
LAST_PORT=20001

install_3proxy

echo "Internal ip = ${IP4}."

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
chmod +x $WORKDIR/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
systemctl start systemd-networkd.service
bash ${WORKDIR}/boot_iptables.sh
ulimit -n 65535
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF

bash /etc/rc.local
