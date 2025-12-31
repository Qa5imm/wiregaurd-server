# WireGuard VPN automation Makefile
# Usage (from this directory):
#   sudo make install
#   sudo make server
#   make set-endpoint WG_ENDPOINT=your.public.ip.or.dns
#   sudo make add-client NAME=phone
#   sudo make show

# Load saved settings if present (e.g. WG_ENDPOINT=...)
-include wg.env

WG_IFACE     ?= wg0
WG_PORT      ?= 51820
WG_NET       ?= 10.8.0.0/24
WG_SERVER_IP ?= 10.8.0.1
WG_DIR       ?= /etc/wireguard
# Auto-detect outbound interface (e.g. enX0, eth0, ens5)
WAN_IFACE    ?= $(shell ip -o -4 route show to default | awk '{print $$5}')
# Used in client configs; set via: make set-endpoint WG_ENDPOINT=1.2.3.4
WG_ENDPOINT  ?= your.server.ip.or.hostname

.PHONY: install server add-client show restart enable-ufw set-endpoint

install:
	sudo apt update
	sudo apt install -y wireguard qrencode iptables ufw iproute2

server:
	sudo bash scripts/wg-setup-server.sh "$(WG_IFACE)" "$(WG_PORT)" "$(WG_NET)" "$(WG_SERVER_IP)" "$(WAN_IFACE)" "$(WG_DIR)"

# Persist WG_ENDPOINT once, so you don't have to pass it every time
set-endpoint:
	@test -n "$(WG_ENDPOINT)" || (echo "Usage: make set-endpoint WG_ENDPOINT=1.2.3.4"; exit 1)
	@echo "WG_ENDPOINT=$(WG_ENDPOINT)" > wg.env
	@echo "Saved WG_ENDPOINT=$(WG_ENDPOINT) to wg.env"

# Add a client by NAME; IP auto-assigned from WG_NET
add-client:
	@test -n "$(NAME)" || (echo "NAME is required, usage: sudo make add-client NAME=phone"; exit 1)
	@test "$(WG_ENDPOINT)" != "your.server.ip.or.hostname" || (echo "Set WG_ENDPOINT via 'make set-endpoint WG_ENDPOINT=your.public.ip'"; exit 1)
	sudo bash scripts/wg-add-client.sh "$(WG_IFACE)" "$(WG_DIR)" "$(NAME)" "$(WG_NET)" "$(WG_ENDPOINT)" "$(WG_PORT)"

show:
	sudo wg show

restart:
	sudo systemctl restart wg-quick@$(WG_IFACE)

enable-ufw:
	# Allow forwarding (router mode)
	sudo sed -i 's/^DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw || true
	# Allow SSH and WireGuard
	sudo ufw allow OpenSSH
	sudo ufw allow $(WG_PORT)/udp
	echo "y" | sudo ufw enable || true
	sudo ufw reload

