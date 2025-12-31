
#!/usr/bin/env bash
set -euo pipefail

# Args:
# 1 = WG_IFACE (e.g. wg0)
# 2 = WG_PORT  (e.g. 51820)
# 3 = WG_NET   (e.g. 10.8.0.0/24)
# 4 = WG_SERVER_IP (e.g. 10.8.0.1)
# 5 = WAN_IFACE (e.g. enX0)
# 6 = WG_DIR  (e.g. /etc/wireguard)

WG_IFACE="$1"
WG_PORT="$2"
WG_NET="$3"
WG_SERVER_IP="$4"
WAN_IFACE="$5"
WG_DIR="$6"

MASK="${WG_NET#*/}"  # e.g. "24" from "10.8.0.0/24"

mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

cd "$WG_DIR"

# Generate server keys if missing
if [[ ! -f server.key ]]; then
  echo "[*] Generating server keypair..."
  umask 077
  wg genkey | tee server.key | wg pubkey > server.pub
fi

if [[ -f "${WG_IFACE}.conf" ]]; then
  echo "[!] ${WG_DIR}/${WG_IFACE}.conf already exists, not overwriting."
else
  echo "[*] Creating ${WG_IFACE}.conf..."
  SERVER_PRIV_KEY=$(cat server.key)

  cat > "${WG_IFACE}.conf" <<EOF
[Interface]
Address = ${WG_SERVER_IP}/${MASK}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV_KEY}

# Enable IP forwarding and NAT when interface comes up
PostUp   = sysctl -w net.ipv4.ip_forward=1; iptables -t nat -A POSTROUTING -s ${WG_NET} -o ${WAN_IFACE} -j MASQUERADE
PostDown = sysctl -w net.ipv4.ip_forward=0; iptables -t nat -D POSTROUTING -s ${WG_NET} -o ${WAN_IFACE} -j MASQUERADE
EOF
fi

echo "[*] Enabling and restarting wg-quick@${WG_IFACE}..."
systemctl enable "wg-quick@${WG_IFACE}"
systemctl restart "wg-quick@${WG_IFACE}"

echo "[*] Current WireGuard status:"
wg show || true
