#!/bin/sh
random() {
        tr </dev/urandom -dc A-Za-z0-9 | head -c5
        echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

genIPV6() {
		
        filename=/root/$1.txt
        [ -f /root/$1.txt ] || echo "" >> /root/$1.txt
        ramdom4() {
                echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
		ramdom2() {
                echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
		
		if [[ $Prefix == "64" || $Prefix == "48" ]]; then
			if [[ $Prefix == "64" ]]; then
				IPV6=$1:$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				while grep -q $IPV6 "$filename"
				do
					echo "$IPV6" >> /root/duplicateipv6.txt
					IPV6=$1:$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				done
				echo "$IPV6" >> /root/$1.txt
				echo "$IPV6"
			else
				IPV6=$1:$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				while grep -q $IPV6 "$filename"
				do
					echo "$IPV6" >> /root/duplicateipv6.txt
					IPV6=$1:$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				done
				echo "$IPV6" >> /root/$1.txt
				echo "$IPV6"
			fi
		else
			if [[ $Prefix == "56" ]]; then
				IPV6=$1$(ramdom2):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				while grep -q $IPV6 "$filename"
				do
					echo "$IPV6" >> /root/duplicateipv6.txt
					IPV6=$1$(ramdom2):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				done
				echo "$IPV6" >> /root/$1.txt
				echo "$IPV6"
			else
				IPV6=$1$(ramdom2):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				while grep -q $IPV6 "$filename"
				do
					echo "$IPV6" >> /root/duplicateipv6.txt
					IPV6=$1$(ramdom2):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4):$(ramdom4)
				done
				echo "$IPV6" >> /root/$1.txt
				echo "$IPV6"
			fi
		fi
        
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 3000
nserver 1.1.1.1
nserver 1.0.0.1
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
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
        echo "$User|$Pass|$Auth|$interface|$IP4|$port|$(genIPV6 $IP6)|$Prefix"
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

echo "Rotation"
rm -fv /home/proxy-installer/data.txt
rm -fv /home/proxy-installer/boot_iptables.sh
rm -fv /home/proxy-installer/boot_ifconfig.sh
rm -fv /home/proxy-installer/3proxy.cfg
echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
WORKDATA2="${WORKDIR}/ipv6-subnet.txt"

IP4=$(curl -4 -s icanhazip.com)
IP6=$(awk -F "|" '{print $1}' ${WORKDATA2})
Prefix=$(awk -F "|" '{print $2}' ${WORKDATA2})
User=$(awk -F "|" '{print $3}' ${WORKDATA2})
Pass=$(awk -F "|" '{print $4}' ${WORKDATA2})
interface=$(awk -F "|" '{print $5}' ${WORKDATA2})
Auth=$(awk -F "|" '{print $6}' ${WORKDATA2})
FIRST_PORT=40000
LAST_PORT=40999
echo "Internal ip = ${IP4}. Exteranl subnet for ip6 = ${IP6}::/${Prefix}"

gen_data >$WORKDIR/data.txt
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x $WORKDIR/boot_*.sh

gen_3proxy >$WORKDIR/3proxy.cfg

rm -fv /usr/local/etc/3proxy/3proxy.cfg
mv $WORKDIR/3proxy.cfg /usr/local/etc/3proxy/
rm -fv /etc/rc.local

/bin/pkill -f '/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg'
systemctl restart network
pid=$(pidof 3proxy)
sudo /bin/kill $pid

cat >>/etc/rc.local <<EOF
touch /var/lock/subsys/local
systemctl start NetworkManager.service
/sbin/ifup ${interface}
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 65535
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF

chmod +x /etc/rc.local
bash /etc/rc.local
