# Troubleshooting — Raspberry Pi Network Security Homelab

## 1. Overview

Throughout this project, I encountered several challenges while configuring Pi-hole, WireGuard, and Linux firewall rules on my Raspberry Pi Zero W.

Rather than simply following installation instructions, I had to investigate network connectivity issues, understand how different services interacted, and determine why certain configurations were not behaving as expected.

This document describes the problems I encountered, the troubleshooting methods I used, and the solutions I implemented.

## 2. DHCP Configuration Issue

### Problem

While configuring my Netgear R7960P router for Pi-hole, I accidentally disabled the router's DHCP server.

After applying the change, my Ubuntu laptop remained connected to Wi-Fi but could no longer access the internet.

Initially, I suspected that the problem was related to DNS because I had been modifying network settings for Pi-hole.

### Investigation

I used Linux networking commands to examine my laptop's network configuration.

```bash
ip -br addr
ip route
```

The results showed that my Wi-Fi interface was active, but my laptop did not have an IPv4 address or a default gateway.

This indicated that the laptop was connected to the wireless network but had not received the network configuration necessary for normal IPv4 communication.

### Root Cause

The Netgear router's DHCP server had been disabled.

DHCP is responsible for automatically providing network configuration information, including:

- IP addresses
- Subnet masks
- Default gateways
- DNS server addresses

Without an active DHCP server, devices configured to obtain their addresses automatically could not receive the necessary IPv4 settings.

### Resolution

To restore connectivity, I temporarily assigned an IPv4 address to my Ubuntu laptop.

```bash
sudo ip addr add 192.168.1.250/24 dev wlp0s20f3
```

This allowed me to access the Netgear router's administration interface using its local IP address.

I then re-enabled the router's DHCP server.

After restoring DHCP, I configured an address reservation for the Raspberry Pi.

| Component | Configuration |
|---|---|
| Router | Netgear R7960P |
| Router IP | `192.168.1.1` |
| DHCP Server | Enabled |
| DHCP Range | `192.168.1.100–192.168.1.200` |
| Raspberry Pi Reservation | `192.168.1.124` |

### Result

Normal network connectivity was restored.

The Raspberry Pi received a consistent IP address through the router's DHCP reservation without requiring the DHCP server to be disabled.

### Lesson Learned

I learned the difference between DNS and DHCP.

**DNS** resolves domain names into IP addresses.

**DHCP** automatically assigns IP addresses and other network configuration information.

This experience reinforced the importance of understanding network settings before modifying them, especially when those changes affect an entire home network.

---

## 3. Verifying Pi-hole DNS Resolution

### Problem

After installing Pi-hole, I needed to verify that it was functioning as a DNS resolver.

Successfully accessing the Pi-hole dashboard alone did not prove that DNS queries were being processed correctly.

### Investigation

I used the `dig` command on my Ubuntu laptop to query Pi-hole directly.

```bash
dig @192.168.1.124 google.com
```

The `@192.168.1.124` argument specifies the DNS server that should receive the query.

This allowed me to test Pi-hole independently of my laptop's automatically configured DNS resolver.

### Result

The DNS query returned:

```text
status: NOERROR
```

The response contained six IPv4 addresses.

This confirmed that Pi-hole was responding to DNS requests and successfully resolving the requested domain.

### Lesson Learned

I learned that service availability should be verified through actual functionality rather than assuming a service is working because its dashboard is accessible.

Testing DNS directly also helped me understand how to isolate DNS-related problems from other networking issues.

---

## 4. DNS Filtering and Query Log Verification

### Problem

After installing Pi-hole, I wanted to confirm that it could block DNS requests based on configured filtering rules.

I also wanted to understand how to interpret the information displayed in Pi-hole's Query Log.

### Investigation

I first reviewed DNS requests recorded by Pi-hole.

One query involved:

```text
Domain: doubleclick.net
Client: 192.168.1.106
```

I then created a controlled blocking test using a custom domain.

### Custom Denylist Configuration

I added the following domain to Pi-hole's exact denylist:

```text
example.com
```

The rule was enabled for the Default group.

I generated another DNS request and reviewed the Pi-hole Query Log.

### Result

The query appeared with a blocked status.

This confirmed that Pi-hole successfully applied the custom denylist rule.

### Lesson Learned

I learned how to distinguish between DNS query logging and actual DNS filtering.

A DNS request appearing in the Query Log does not automatically mean it was blocked.

The filtering status must be reviewed to determine whether Pi-hole allowed or denied the request.

I also learned that controlled tests are useful when validating security configurations because they produce predictable results.

---

## 5. WireGuard Service Configuration Issue

### Problem

While configuring WireGuard, I encountered an error when attempting to enable a systemd service.

The error stated:

```text
The unit files have no installation config
(WantedBy=, RequiredBy=, ...)
```

Initially, I was unfamiliar with how systemd template services worked.

### Investigation

I reviewed the WireGuard service configuration and learned that WireGuard uses an instance-based systemd service.

The service name must include the WireGuard interface.

For my configuration, the interface was:

```text
wg0
```

### Resolution

I used the correct instance-specific service name:

```bash
sudo systemctl start wg-quick@wg0
```

To enable the service at startup:

```bash
sudo systemctl enable wg-quick@wg0
```

I verified the service using:

```bash
sudo systemctl status wg-quick@wg0
```

I also checked the WireGuard interface:

```bash
sudo wg show
```

### Result

The WireGuard interface started successfully.

I continued configuring my iPhone and Ubuntu laptop as VPN clients.

### Lesson Learned

I learned that systemd supports template services that require an instance name.

I also learned that a running WireGuard interface does not necessarily mean a VPN client has established a connection.

A recent handshake and successful traffic exchange provide stronger evidence of connectivity.

---

## 6. WireGuard VPN-to-LAN Connectivity

### Problem

After configuring WireGuard, I wanted VPN clients to access other devices on my home network rather than only services running on the Raspberry Pi.

I discovered that IPv4 forwarding was disabled.

### Investigation

I checked the Raspberry Pi's forwarding configuration:

```bash
sysctl net.ipv4.ip_forward
```

The output was:

```text
net.ipv4.ip_forward = 0
```

This meant the Raspberry Pi was not configured to forward IPv4 packets between network interfaces.

### Resolution

I enabled IPv4 forwarding:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

I also configured NAT masquerading to allow VPN clients to communicate with devices on the home LAN.

```bash
sudo iptables -t nat -A POSTROUTING \
  -s 10.8.0.0/24 \
  -d 192.168.1.0/24 \
  -o wlan0 \
  -j MASQUERADE
```

Next, I configured forwarding rules.

**VPN to LAN:**

```bash
sudo iptables -A FORWARD \
  -i wg0 -o wlan0 \
  -s 10.8.0.0/24 \
  -d 192.168.1.0/24 \
  -j ACCEPT
```

**LAN to VPN return traffic:**

```bash
sudo iptables -A FORWARD \
  -i wlan0 -o wg0 \
  -s 192.168.1.0/24 \
  -d 10.8.0.0/24 \
  -m conntrack --ctstate ESTABLISHED,RELATED \
  -j ACCEPT
```

### Result

After configuring IP forwarding, NAT, and firewall forwarding rules, I successfully tested access to my home network through WireGuard.

### Lesson Learned

I learned the difference between traffic destined for the Raspberry Pi and traffic passing through it.

- **INPUT:** Traffic destined for the Raspberry Pi.
- **OUTPUT:** Traffic originating from the Raspberry Pi.
- **FORWARD:** Traffic routed through the Raspberry Pi.

I also learned how NAT allows devices on different private networks to communicate without requiring every device to have a route to the VPN subnet.

---

## 7. Learning iptables and Firewall Management

### Challenge

Before this project, I had not worked directly with `iptables`.

I wanted to understand how to configure firewall rules manually rather than relying entirely on a graphical firewall interface.

### Investigation

I installed `iptables` and checked its version:

```bash
sudo iptables --version
```

The system reported:

```text
iptables v1.8.11 (nf_tables)
```

I inspected the firewall policies:

```bash
sudo iptables -S
```

Initially, the output showed:

```text
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

This meant the default IPv4 policies allowed unmatched traffic.

### Configuration

I added rules for:

- SSH from the home network
- DNS over TCP and UDP
- WireGuard UDP port 51820
- DNS requests from VPN clients
- Pi-hole dashboard access
- Established and related connections
- Loopback communication
- DHCP responses
- VPN-to-LAN forwarding

I inspected the rules using:

```bash
sudo iptables -L INPUT -n -v --line-numbers
```

The packet counters showed that several rules were matching network traffic.

### Current Status

At the time of my last confirmed configuration, the firewall still used default ACCEPT policies.

Although service-specific allow rules were configured, a complete default-deny firewall had not yet been validated.

### Lesson Learned

I learned that creating ACCEPT rules does not automatically restrict network traffic.

A firewall with an ACCEPT default policy will continue allowing unmatched traffic unless another rule blocks it.

I also learned the importance of checking packet counters and understanding rule order.

---

## 8. Firewall Backup and Recovery Planning

### Challenge

Because I was managing the Raspberry Pi through SSH, changing firewall rules introduced the risk of accidentally blocking my own administrative connection.

### Approach

Before testing restrictive firewall policies, I backed up the working configuration.

```bash
sudo iptables-save > /root/iptables-working.rules
```

I also explored using a temporary systemd rollback timer.

```bash
sudo systemd-run \
  --unit=firewall-rollback \
  --on-active=5m \
  /usr/sbin/iptables-restore /root/iptables-working.rules
```

The purpose of the timer was to restore the previous firewall configuration if restrictive rules interrupted SSH connectivity.

### Lesson Learned

I learned that firewall configuration requires planning for recovery, especially when managing systems remotely.

Maintaining backups and preparing rollback procedures can reduce the risk of losing access during security changes.

---

## 9. Troubleshooting Commands Reference

| Command | Purpose |
|---|---|
| `ip -br addr` | Display network interfaces and IP addresses |
| `ip route` | Display IPv4 routing information |
| `hostname -I` | Display assigned IP addresses |
| `dig @192.168.1.124 google.com` | Test Pi-hole DNS resolution |
| `sudo wg show` | Inspect WireGuard peers and handshakes |
| `ip -br addr show wg0` | Verify the WireGuard interface |
| `sysctl net.ipv4.ip_forward` | Check IPv4 forwarding |
| `sudo iptables -S` | Display firewall rules |
| `sudo iptables -L -n -v` | Inspect firewall counters |
| `sudo iptables -t nat -S` | Display NAT rules |
| `sudo ss -tulpn` | Inspect listening network services |
| `sudo systemctl status pihole-FTL` | Check Pi-hole service status |

## 10. Conclusion

Troubleshooting was one of the most valuable parts of this project.

I encountered problems involving DHCP configuration, DNS filtering verification, WireGuard service management, VPN routing, and firewall configuration.

Working through these challenges helped me develop a better understanding of Linux networking and how different network services interact.

Most importantly, I learned to investigate problems systematically by examining network configuration, testing connectivity, reviewing logs, and verifying results before making additional changes.