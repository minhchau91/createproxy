#!/bin/sh
random() {
        tr </dev/urandom -dc A-Za-z0-9 | head -c5
        echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
        ip64() {
                echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
        echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
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
"proxy -6 -n -a -p" $6 " -i" $5 " -e"$7"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >/root/proxylist.txt <<EOF
$(awk -F "|" '{print $5 ":" $6}' ${WORKDATA})
EOF
}

upload_proxy() {
    cd $WORKDIR
    local PASS1=$(random)
    zip --password $PASS1 proxy.zip /root/proxylist.txt
    URL=$(curl -F "file=@proxy.zip" https://file.io)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS1"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS1}"

}
gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$User|$Pass|$Auth|$interface|$IP4|$port|$(gen64 $IP6)|$Prefix"
    done
}

gen_iptables() {
    cat <<EOF
    $(awk -F "|" '{print "/sbin/iptables -I INPUT -p tcp --dport " $6 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "|" '{print "/sbin/ifconfig " $4 " inet6 add " $7"/"$8}' ${WORKDATA})
EOF
}

/sbin/service network restart
#/sbin/iptables -F INPUT
echo "installing apps"
rm -fv /usr/local/etc/3proxy/3proxy.cfg
rm -fv /home/proxy-installer/data.txt
rm -fv /home/proxy-installer/boot_iptables.sh
rm -fv /home/proxy-installer/boot_ifconfig.sh
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf
echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
WORKDATA2="${WORKDIR}/ipv6-subnet.txt"

IP4=$(awk -F "|" '{print $7}' ${WORKDATA2})
IP6=$(awk -F "|" '{print $1}' ${WORKDATA2})
Prefix=$(awk -F "|" '{print $2}' ${WORKDATA2})
User=$(awk -F "|" '{print $3}' ${WORKDATA2})
Pass=$(awk -F "|" '{print $4}' ${WORKDATA2})
interface=$(awk -F "|" '{print $5}' ${WORKDATA2})
Auth=$(awk -F "|" '{print $6}' ${WORKDATA2})
FIRST_PORT=$(awk -F "|" '{print $8}' ${WORKDATA2})
LAST_PORT=$(awk -F "|" '{print $9}' ${WORKDATA2})
echo "FIRST_PORT = ${FIRST_PORT}. LAST_PORT = ${LAST_PORT}"

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"

gen_data >$WORKDIR/data.txt
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x $WORKDIR/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

rm -fv /etc/rc.local

cat >>/etc/rc.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup ${interface}
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 65535
/bin/pkill -f '/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg'
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf
EOF
chmod +x /etc/rc.local
bash /etc/rc.local
