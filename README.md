# Wireguard Server

Tiny Makefile + shell scripts to turn a fresh Linux VPS into a WireGuard VPN server and auto-generate client configs (with QR codes).

Tested on Ubuntu (20.04/22.04); should work on other Debian-like systems with minor tweaks.

## Features

- One-command WireGuard server setup (NAT + IP forwarding)
- UFW config for VPN routing
- Auto-assigned client IPs (from `10.8.0.0/24`)
- Per-client configs written to `/etc/wireguard/clients/`
- QR code output for easy import into the WireGuard mobile app

## Requirements

Run on the VPS:

- Ubuntu / Debian
- `sudo` access
- Open UDP port `51820` in your cloud firewall / security group

## Quick start

```bash
git clone https://github.com/Qa5imm/wiregaurd-server.git
cd wiregaurd-server

# Install make dependency
sudo apt install make

# Install all required dependencies
sudo make install

# Set up WireGuard server (wg0, 10.8.0.1/24, NAT)
sudo make server

# Enable UFW forwarding and allow SSH + UDP 51820
sudo make enable-ufw

# Set your public endpoint (VPS public IP)
make set-endpoint WG_ENDPOINT=your.public.ip

# Add a new client (auto IP + QR in terminal)
sudo make add-client NAME=android-phone
```

## Connection

### Phone
Download the wireguard mobile app on Android/iOS and scan the QR code

### Laptop
Download the wireguard (client)[https://www.wireguard.com/install/] and upload the config file found under /etc/wireguard/clients/<NAME>.conf

## Common Commnads

# Show WireGuard status
sudo make show

# Restart the VPN interface
sudo make restart

# Add more clients
sudo make add-client NAME=laptop
sudo make add-client NAME=tablet

### Notes

Default VPN subnet: `10.8.0.0/24`
Server VPN IP: `10.8.0.1`
Clients get `10.8.0.2–10.8.0.254` automatically.
Script assumes `/24` network; adjust if you change WG_NET significantly.