#!/usr/bin/env bash
set -euo pipefail

# Args:
# 1 = WG_IFACE    (e.g. wg0)
# 2 = WG_DIR      (e.g. /etc/wireguard)
# 3 = NAME        (e.g. phone)
# 4 = WG_NET      (e.g. 10.8.0.0/24)
# 5 = WG_ENDPOINT (public IP or hostname)
# 6 = WG_PORT     (e.g. 51820)

WG_IFACE="$1"
WG_DIR="$2"
NAME="$3"
WG_NET="$4"
WG_ENDPOINT="$5"
WG_PORT="$6"

CLIENT_DIR="${WG_DIR}/clients"
mkdir -p "$CLIENT_DIR"
chmod 700 "$CLIENT_DIR"

cd "$WG_DIR"

if [[ ! -f server.pub ]]; then
  echo "[!] server.pub not found in ${WG_DIR}. Run server setup first." >&2
  exit 1
fi

CLIENT_KEY_FILE="${CLIENT_DIR}/${NAME}.key"
CLIENT_PUB_FILE="${CLIENT_DIR}/${NAME}.pub"
CLIENT_CONF_FILE="${CLIENT_DIR}/${NAME}.conf"

if [[ -f "$CLIENT_CONF_FILE" ]]; then
  echo "[!] Client ${NAME} already exists at ${CLIENT_CONF_FILE}" >&2
  exit 1
fi

# --- Auto-assign IP from WG_NET (assumes /24) ---

NET_IP="${WG_NET%/*}"  # e.g. 10.8.0.0
MASK="${WG_NET#*/}"    # e.g. 24

if [[ "$MASK" != "24" ]]; then
  echo "[!] Auto IP assignment currently assumes /24 network, got /${MASK}" >&2
  exit 1
fi

BASE_PREFIX=$(echo "$NET_IP" | awk -F. '{print $1"."$2"."$3}')  # e.g. 10.8.0
# We'll start assigning from .2 upwards (assuming .1 is server)
ASSIGNED_IP=""

echo "[*] Scanning for free IP in ${WG_NET}..."
for host in $(seq 2 254); do
  CAND="${BASE_PREFIX}.${host}"
  # Check if this IP already appears in wg0.conf as an AllowedIPs entry
  if ! grep -Eq "AllowedIPs *= *${CAND}/32" "${WG_IFACE}.conf"; then
    ASSIGNED_IP="$CAND"
    break
  fi
done

if [[ -z "${ASSIGNED_IP}" ]]; then
  echo "[!] No free IPs found in ${WG_NET}" >&2
  exit 1
fi

echo "[*] Assigned IP ${ASSIGNED_IP} to client '${NAME}'"

# --- Generate keys for client ---

echo "[*] Generating keypair for client '${NAME}'..."
umask 077
wg genkey | tee "$CLIENT_KEY_FILE" | wg pubkey > "$CLIENT_PUB_FILE"

CLIENT_PRIV_KEY=$(cat "$CLIENT_KEY_FILE")
CLIENT_PUB_KEY=$(cat "$CLIENT_PUB_FILE")
SERVER_PUB_KEY=$(cat server.pub)

# --- Append peer to server config ---

echo "[*] Appending peer to ${WG_IFACE}.conf..."
cat >> "${WG_IFACE}.conf" <<EOF

[Peer]
# ${NAME}
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = ${ASSIGNED_IP}/32
EOF

# --- Write client config ---

echo "[*] Writing client config to ${CLIENT_CONF_FILE}..."
cat > "$CLIENT_CONF_FILE" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${ASSIGNED_IP}/32
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB_KEY}
Endpoint = ${WG_ENDPOINT}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "[*] Restarting wg-quick@${WG_IFACE}..."
systemctl restart "wg-quick@${WG_IFACE}"

echo "[*] Done."
echo "Client '${NAME}' assigned IP: ${ASSIGNED_IP}"
echo "Client config: ${CLIENT_CONF_FILE}"

# --- Auto-generate QR code for Android/iOS ---

if command -v qrencode >/dev/null 2>&1; then
  echo
  echo "[*] QR code for '${NAME}' (scan with WireGuard app):"
  qrencode -t ansiutf8 < "${CLIENT_CONF_FILE}"
  echo
else
  echo "[!] qrencode not found. Install it with: apt install qrencode"
fi

