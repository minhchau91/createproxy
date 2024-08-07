#!/bin/sh
random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
#gen64() {
#	ip64() {
#		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
#	}
#	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64):$(ip64)"
#}

gen64() {
        filename=/root/$1.txt
        [ -f /root/$1.txt ] || echo "" >> /root/$1.txt
        ip64() {
                echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
        IPV6=$1:$(ip64):$(ip64):$(ip64):$(ip64):$(ip64)
        while grep -q $IPV6 "$filename"
        do
                echo "$IPV6" >> /root/duplicateipv6.txt
                IPV6=$1:$(ip64):$(ip64):$(ip64):$(ip64):$(ip64)
        done
        echo "$IPV6" >> /root/$1.txt
        echo "$IPV6"
}

install_3proxy() {
    echo "installing 3proxy"
    mkdir -p /3proxy
    cd /3proxy
    URL="https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
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
    systemctl stop firewalld
    systemctl disable firewalld

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
    $(awk -F "|" '{print "iptables -I INPUT -p tcp --dport " $6 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "|" '{print "ifconfig " $4 " inet6 add " $7"/"$8}' ${WORKDATA})
EOF
}
sysctl -w net.ipv6.conf.eth0.accept_dad=0
echo "installing apps"
yum -y --skip-broken install gcc net-tools bsdtar zip make >/dev/null 
sudo yum -y --skip-broken install epel-release
sudo yum -y --skip-broken install shc


echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
checkIP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
#IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
echo "Detected your ipv4: $IP4" 
echo "Detected your ipv6: $checkIP6" 
#read -p "What is your ipv6 prefix? (exp: /56, /64): " Prefix
Prefix=48
read -p "What is your ipv6 subnet? (exp: 2600:3c00:e002): " IP6
#checkinterface=$(ip addr show | awk '/inet.*brd/{print $NF}')
echo "Detected your active interface: $checkinterface"
#read -p "Please confirm your active network interface : " interface
interface=eth1

#while true; do
#    read -p "Do you want to create auth for your proxy? (Y/N): " authConfirm
#    case $authConfirm in
#        [Yy]* ) Auth=strong; read -p "Input UserName? " User; read -p "Input PassWord: " Pass; break;;
#        [Nn]* ) Auth=none;User=minhchau; Pass=minhchau@123; break;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
Auth=none
User=drt
Pass=drt2024

#read -p "Please input start port :" FIRST_PORT
#read -p "Please input start port :" LAST_PORT
FIRST_PORT=31000
LAST_PORT=31999

rm -fv $WORKDIR/ipv6-subnet.txt
cat >>$WORKDIR/ipv6-subnet.txt <<EOF
${IP6}|${Prefix}|${User}|${Pass}|${interface}|${Auth}
EOF


install_3proxy

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"



gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x $WORKDIR/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
systemctl start NetworkManager.service
ifup ${interface}
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 65535
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF

bash /etc/rc.local

gen_proxy_file_for_user

wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/Rotation_48.sh" --output-document=/etc/centos.sh
shc -r -f /etc/centos.sh -o /root/Rotation.sh
chmod 777 /root/Rotation.sh

#Restart Network
wget "https://raw.githubusercontent.com/minhchau91/createproxy/main/rebootNetwork.sh" --output-document=/etc/rebootcentos.sh
shc -r -f /etc/rebootcentos.sh -o /root/rebootNetwork.sh
chmod 777 /root/rebootNetwork.sh

#Add Cronjob
#cat >>/var/spool/cron/root<<EOF
#day
#00 7 */5 * * /root/Rotation.sh > /root/Rotation_log.txt
#day - time
#59 7 * * * /root/Rotation.sh > /root/Rotation_log.txt
#59 21 * * * /root/Rotation.sh > /root/Rotation_log.txt
#0 2 * * * /root/Rotation.sh > /root/Rotation_log.txt
#0 14 * * * /root/Rotation.sh > /root/Rotation_log.txt
#minutes
#*/30 * * * * /root/Rotation.sh > /root/Rotation_log.txt
#*/15 * * * * /root/Rotation.sh > /root/Rotation_log.txt
#hour
#0 * * * * /root/Rotation.sh > /root/Rotation_log.txt
#0 */12 * * * /root/Rotation.sh > /root/Rotation_log.txt
0 */4 * * * /root/Rotation.sh > /root/Rotation_log.txt
#Special date of month
#0 12 3 * * /root/Rotation.sh > /root/Rotation_log.txt
#0 0 5 * * /root/Rotation.sh > /root/Rotation_log.txt
#RebootNetwork
#30-55/30 */4 * * * /root/rebootNetwork.sh > /root/rebootNetwork_log.txt
#EOF
