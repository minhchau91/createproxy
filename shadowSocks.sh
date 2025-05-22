#!/usr/bin/env bash
# Combined installer for SOCKS5 (Dante) and/or Shadowsocks-libev on Ubuntu/Debian/RedHat

set -e

# Detect OS
OS=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian) OS="debian" ;;        
        amzn|centos|rhel|rocky|almalinux) OS="redhat" ;;        
        *) echo "❌ Unsupported OS: $ID"; exit 1 ;;    
    esac
else
    echo "❌ Cannot detect OS."; exit 1
fi

# Prompt user for type
echo "Select server(s) to install:"
echo "  1) SOCKS5 (Dante)"
echo "  2) Shadowsocks-libev"
echo "  3) Both SOCKS5 and Shadowsocks-libev"
read -p "Enter choice [1, 2, or 3]: " choice

# Common variables
EXT_IF=$(ip route | awk '/default/ {print $5; exit}')
EXT_IF=${EXT_IF:-eth0}
PUBLIC_IP=$(curl -4 -s https://api.ipify.org)

install_socks5() {
    local USERNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c8)"
    local PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c12)"
    local PORT=$(shuf -i 1025-65000 -n1)

    # Install packages
    if [ "$OS" = "debian" ]; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y dante-server curl iptables iptables-persistent
    else
        yum install -y epel-release
        yum install -y dante-server curl iptables-services
        systemctl enable iptables
        systemctl start iptables
    fi

    # Create user
    useradd -M -N -s /usr/sbin/nologin "$USERNAME"
    echo "${USERNAME}:${PASSWORD}" | chpasswd

    # Configure Dante
    [ -f /etc/danted.conf ] && cp /etc/danted.conf /etc/danted.conf.bak.$(date +%F_%T)
    cat > /etc/danted.conf <<EOF
logoutput: syslog /var/log/danted.log

internal: 0.0.0.0 port = ${PORT}
external: ${EXT_IF}

method: pam
user.privileged: root
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF

    chmod 644 /etc/danted.conf
    systemctl restart danted
    systemctl enable danted

    # Open firewall
    if command -v ufw >/dev/null 2>&1; then
        ufw allow "${PORT}/tcp"
    else
        iptables -I INPUT -p tcp --dport "${PORT}" -j ACCEPT
        iptables-save > /etc/iptables/rules.v4 || true
    fi

    # Return single-line credentials
    echo "${PUBLIC_IP}:${PORT}:${USERNAME}:${PASSWORD}"
}

install_shadowsocks() {
    local PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c16)
    local SERVER_PORT=$((RANDOM % 50000 + 10000))
    local METHOD="aes-256-gcm"
    local CONFIG_PATH="/etc/shadowsocks-libev/config.json"

    # Install packages
    if [ "$OS" = "debian" ]; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y shadowsocks-libev qrencode curl iptables iptables-persistent
    else
        yum install -y epel-release
        yum install -y shadowsocks-libev qrencode curl firewalld
        systemctl enable firewalld
        systemctl start firewalld
    fi

    # Configure Shadowsocks
    cat > "$CONFIG_PATH" <<EOF
{
    "server":"0.0.0.0",
    "server_port":${SERVER_PORT},
    "password":"${PASSWORD}",
    "timeout":300,
    "method":"${METHOD}",
    "fast_open": false,
    "nameserver":"1.1.1.1",
    "mode":"tcp_and_udp"
}
EOF

    # Open firewall
    if [ "$OS" = "debian" ]; then
        if command -v ufw >/dev/null 2>&1; then
            ufw allow ${SERVER_PORT}/tcp
            ufw allow ${SERVER_PORT}/udp
        else
            iptables -I INPUT -p tcp --dport ${SERVER_PORT} -j ACCEPT
            iptables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
            iptables-save > /etc/iptables/rules.v4 || true
        fi
    else
        firewall-cmd --permanent --add-port=${SERVER_PORT}/tcp
        firewall-cmd --permanent --add-port=${SERVER_PORT}/udp
        firewall-cmd --reload
    fi

    systemctl enable shadowsocks-libev
    systemctl restart shadowsocks-libev

    # Generate SS URL and QR
    local SS_BASE64=$(echo -n "${METHOD}:${PASSWORD}@${PUBLIC_IP}:${SERVER_PORT}" | base64 -w0)
    local SS_URL="ss://${SS_BASE64}"
    local INFO_LINE="${PUBLIC_IP}:${SERVER_PORT}:${METHOD}:${PASSWORD}"

    # Return multi-line: info + QR code
    echo "${INFO_LINE}"
    echo "QR Code:"
    qrencode -t ANSIUTF8 "${SS_URL}"
}

case "$choice" in
    1)
        install_socks5
        ;;
    2)
        install_shadowsocks
        ;;
    3)
        # Install both, capture outputs and display together
        socks_info=$(install_socks5)
        ss_output=$(install_shadowsocks)
        echo "-- SOCKS5 --"
        echo "$socks_info"
        echo "-- Shadowsocks --"
        echo "$ss_output"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
