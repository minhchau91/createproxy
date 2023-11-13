#!/bin/bash

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


WORKDIR="/home/proxy-installer"
WORKDATA2="${WORKDIR}/ipv6-subnet.txt"

line_number=$1

old_ipv6=$(sed -n "${line_number}p" ${WORKDIR}/boot_ifconfig.sh | awk '{print $5}' | rev | cut -c 4- | rev)

IP6=$(awk -F "|" '{print $1}' ${WORKDATA2})
Prefix=$(awk -F "|" '{print $2}' ${WORKDATA2})
interface=$(awk -F "|" '{print $5}' ${WORKDATA2})

new_ipv6=$(genIPV6 $IP6)

sed -i "s/${old_ipv6}/${new_ipv6}/g" /usr/local/etc/3proxy/3proxy.cfg
sed -i "s/${old_ipv6}/${new_ipv6}/g" ${WORKDIR}/boot_ifconfig.sh

/sbin/ifconfig $interface inet6 del $old_ipv6/$Prefix
/sbin/ifconfig $interface inet6 add $new_ipv6/$Prefix

pid=$(pidof 3proxy)
sudo /bin/kill -SIGUSR1 $pid

echo "done"
