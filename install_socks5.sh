#!/bin/bash
USERNAME=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)
PORT=$(shuf -i 20000-40000 -n 1)
EMAIL="172.237.12.54"

echo "=== Cài đặt SOCKS5 Proxy ==="
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt update && apt install -y dante-server curl iptables-persistent

IP=$(curl -4 -s ifconfig.me)
if [[ -z "$IP" ]]; then
    echo -e "\e[31m❌ Không lấy được IP Public. Kiểm tra kết nối Internet.\e[0m"
    exit 1
fi

INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
if [[ -z "$INTERFACE" ]]; then
    echo -e "\e[31m❌ Không xác định được interface mạng chính.\e[0m"
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    useradd -M -s /usr/sbin/nologin "$USERNAME"
fi

HASH=$(openssl passwd -6 "$PASSWORD")
usermod -p "$HASH" "$USERNAME"

cat <<EOL > /etc/danted.conf
logoutput: syslog
internal: 0.0.0.0 port = $PORT
external: $INTERFACE
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody
clientmethod: none
socksmethod: username
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    method: username
    log: connect disconnect error
}
EOL

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
iptables-save > /etc/iptables/rules.v4
systemctl restart danted
systemctl enable danted


# Gửi thông tin proxy tới API
#curl -s -X POST https://proxy.rrrb.xyz/api/proxy.php \
#    -H "Content-Type: application/json" \
#    -d '{
#        "ip": "'"$IP"'",
#        "port": "'"$PORT"'",
#        "username": "'"$USERNAME"'",
#        "password": "'"$PASSWORD"'",
#        "protocol": "socks",
#        "email": "'"$EMAIL"'"
#    }'

echo "$IP:$PORT:$USERNAME:$PASSWORD"
echo -e "\e[32m✅ SOCKS5 proxy đã chạy thành công!\e[0m"
