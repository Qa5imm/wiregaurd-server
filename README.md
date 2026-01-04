# Wireguard Server

Tiny Makefile + shell scripts to turn a fresh Linux VPS into a WireGuard VPN server and auto-generate client configs (with QR codes).

Tested on Ubuntu (24.04); should work on other Debian-like systems with minor tweaks.

## Features

- One-command WireGuard server setup (NAT + IP forwarding)
- UFW config for VPN routing
- Auto-assigned client IPs (from `10.8.0.0/24`)
- Per-client configs written to `/etc/wireguard/clients/`
- QR code output for easy import into the WireGuard mobile app

## Requirements

-  Debian based linux distro
- `sudo` access
- Open UDP port `51820` in your cloud firewall / security group

## Quick start

```bash

# Step 0
ssh into your linux distro

# Step 1
git clone https://github.com/Qa5imm/wiregaurd-server.git
cd wiregaurd-server

# Step 2 (install make)
sudo apt install make

# Step 3 (install required dependencies)
sudo make install

# Step 4 (set up WireGuard server)
sudo make server

# Step 5 (enable UFW forwarding and allow SSH + UDP 51820)
sudo make enable-ufw

# Step 6 (set your VPS public IP)
make set-endpoint WG_ENDPOINT=your.public.ip

# Step 7 (Add a client)
sudo make add-client NAME=myphone
```

## Connection

### Phone
Download the wireguard mobile app on Android/iOS and scan the QR code

### Laptop
Download the wireguard [client](https://www.wireguard.com/install/) and upload the config file found under `/etc/wireguard/clients/<NAME>.conf`

## Common Commnads

```bash
# Show WireGuard status
sudo make show

# Restart the VPN interface
sudo make restart

# Add more clients
sudo make add-client NAME=laptop
sudo make add-client NAME=tablet
```

### Notes

- Default VPN subnet: `10.8.0.0/24`
- Server VPN IP: `10.8.0.1`
- Clients get `10.8.0.2–10.8.0.254` automatically.