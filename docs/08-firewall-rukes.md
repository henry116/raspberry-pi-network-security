# Raspberry Pi Firewall Hardening Using iptables

## 1. Project Overview

As part of my Raspberry Pi Network Security Homelab, I began implementing a Linux host firewall using `iptables` to improve the security of my Pi-hole DNS server and WireGuard VPN.

My goal was to understand how Linux firewalls process network traffic and how firewall rules can be used to control access to specific services.

This project allowed me to gain hands-on experience with packet filtering, network protocols, connection tracking, Network Address Translation (NAT), and VPN traffic forwarding.

Rather than using a preconfigured firewall, I manually created rules to better understand how Linux handles incoming and forwarded network traffic.

## 2. Project Objectives

The main objectives were:

1. Learn the fundamentals of Linux `iptables`.
2. Understand firewall tables, chains, and policies.
3. Configure firewall rules for SSH administration.
4. Allow DNS traffic required by Pi-hole.
5. Allow WireGuard VPN connections.
6. Restrict access to administrative services.
7. Configure VPN-to-LAN forwarding.
8. Implement NAT masquerading for VPN clients.
9. Prepare a default-deny firewall configuration.
10. Document firewall configuration and testing.

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| Raspberry Pi Zero W | Hosts network services |
| Raspberry Pi OS 13 (Trixie) | Linux operating system |
| iptables | IPv4 firewall configuration |
| nftables | Underlying packet-filtering framework |
| Pi-hole | DNS filtering |
| WireGuard | Encrypted VPN connectivity |
| SSH | Remote administration |
| Netgear R7960P | Home router |
| Linux systemd | Service management |
| GitHub | Technical documentation |

## 4. Network Architecture

My Raspberry Pi hosts both Pi-hole and WireGuard.

The firewall controls incoming connections to these services and traffic forwarded between VPN clients and the home network.

```text
                    INTERNET
                       |
                       v
                NETGEAR ROUTER
                 192.168.1.1
                       |
                       v
                RASPBERRY PI
                 192.168.1.124
                       |
                  iptables
                       |
             +---------+---------+
             |                   |
             v                   v
          Pi-hole             WireGuard
         DNS Server           VPN Server
          Port 53             UDP 51820
                                 |
                          VPN Clients
                         10.8.0.0/24
                                 |
                                 v
                          Home Network
                         192.168.1.0/24
```

### Network Configuration

| Component | Configuration |
|---|---|
| Raspberry Pi | `192.168.1.124` |
| Home Router | `192.168.1.1` |
| Home LAN | `192.168.1.0/24` |
| WireGuard Server | `10.8.0.1` |
| WireGuard VPN Subnet | `10.8.0.0/24` |
| LAN Interface | `wlan0` |
| VPN Interface | `wg0` |

## 5. Understanding iptables

Before configuring the firewall, I learned how `iptables` organizes packet-filtering rules.

### Firewall Chains

| Chain | Purpose |
|---|---|
| INPUT | Processes traffic destined for the Raspberry Pi |
| OUTPUT | Processes traffic originating from the Raspberry Pi |
| FORWARD | Processes traffic routed through the Raspberry Pi |

### Firewall Actions

| Action | Description |
|---|---|
| ACCEPT | Allows matching traffic |
| DROP | Silently discards matching traffic |
| REJECT | Rejects matching traffic, typically with an error response |

### Firewall Tables

The main tables I worked with were:

**Filter Table**

Used to control whether network packets are allowed or blocked.

**NAT Table**

Used to translate network addresses when traffic passes between networks.

## 6. Initial Firewall Inspection

I installed and verified `iptables` using:

```bash
sudo apt install iptables -y
sudo iptables --version
```

The system reported:

```text
iptables v1.8.11 (nf_tables)
```

This confirmed that the system was using the `iptables` interface with the nftables compatibility backend.

I inspected the existing rules:

```bash
sudo iptables -S
sudo iptables -t nat -S
```

Initially, the filter table contained:

```text
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

This meant unmatched IPv4 traffic was allowed by default.

## 7. SSH Firewall Configuration

The first rule I implemented allowed SSH access from my home network.

```bash
sudo iptables -A INPUT \
  -s 192.168.1.0/24 \
  -p tcp --dport 22 \
  -j ACCEPT
```

### Explanation

- `-A INPUT`: Appends a rule to the INPUT chain.
- `-s`: Specifies the source network.
- `-p tcp`: Matches TCP traffic.
- `--dport 22`: Matches SSH connections.
- `-j ACCEPT`: Allows matching traffic.

This rule was designed to preserve SSH administration from devices on my home network.

Because the default INPUT policy remained ACCEPT, this rule did not yet prevent SSH connections from other sources.

## 8. Pi-hole DNS Firewall Rules

Pi-hole requires DNS traffic on both UDP and TCP port 53.

I created separate rules for each protocol.

### UDP DNS

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -s 192.168.1.0/24 \
  -p udp --dport 53 \
  -j ACCEPT
```

### TCP DNS

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -s 192.168.1.0/24 \
  -p tcp --dport 53 \
  -j ACCEPT
```

### Why Both Protocols?

UDP is commonly used for standard DNS queries.

TCP is also used for DNS, including certain responses that cannot be handled within the available UDP message size.

Allowing both protocols helps ensure normal DNS operation.

### Verification

I inspected the firewall counters:

```bash
sudo iptables -L INPUT -n -v --line-numbers
```

The counters showed traffic matching both DNS rules.

This confirmed that DNS packets were reaching the configured firewall rules.

## 9. WireGuard VPN Firewall Configuration

WireGuard uses UDP for encrypted VPN communication.

My WireGuard server was configured to listen on UDP port 51820.

I added:

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -p udp --dport 51820 \
  -j ACCEPT
```

This allows incoming WireGuard traffic to reach the VPN server.

Unlike SSH, the rule does not restrict the source to my home network because authorized VPN clients may connect from external networks.

WireGuard's cryptographic peer authentication determines which clients can establish an authenticated VPN connection.

## 10. Allowing DNS Over WireGuard

I wanted my iPhone and Ubuntu laptop to use Pi-hole while connected through WireGuard.

I configured rules allowing DNS traffic from the VPN subnet.

### UDP DNS

```bash
sudo iptables -A INPUT \
  -i wg0 \
  -s 10.8.0.0/24 \
  -p udp --dport 53 \
  -j ACCEPT
```

### TCP DNS

```bash
sudo iptables -A INPUT \
  -i wg0 \
  -s 10.8.0.0/24 \
  -p tcp --dport 53 \
  -j ACCEPT
```

These rules permit VPN clients to access Pi-hole's DNS service through the WireGuard interface.

The firewall counters showed packets matching the VPN UDP DNS rule.

## 11. Pi-hole Dashboard Access

Pi-hole provides a web administration interface.

I configured rules to allow access from the home network.

### HTTP

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -s 192.168.1.0/24 \
  -p tcp --dport 80 \
  -j ACCEPT
```

### HTTPS

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -s 192.168.1.0/24 \
  -p tcp --dport 443 \
  -j ACCEPT
```

These rules are intended to allow trusted local devices to access the Pi-hole dashboard.

Once a default-deny policy is implemented, unmatched IPv4 connections to these ports would be blocked.

## 12. Connection Tracking

I configured a rule to allow established and related network traffic.

```bash
sudo iptables -I INPUT 1 \
  -m conntrack \
  --ctstate ESTABLISHED,RELATED \
  -j ACCEPT
```

### Explanation

Connection tracking allows the firewall to recognize traffic associated with existing connections.

For example, when the Raspberry Pi sends a DNS request to an upstream resolver, the corresponding response can be recognized as part of an established exchange.

Placing this rule at the beginning of the INPUT chain allows matching return traffic before later rules are evaluated.

## 13. Loopback and DHCP

### Loopback

```bash
sudo iptables -A INPUT -i lo -j ACCEPT
```

This permits local communication through the loopback interface.

### DHCP

```bash
sudo iptables -A INPUT \
  -i wlan0 \
  -p udp --sport 67 --dport 68 \
  -j ACCEPT
```

This permits DHCP server responses to reach the Raspberry Pi.

The Netgear router remains responsible for DHCP, while the Raspberry Pi receives its local address through a DHCP reservation.

## 14. WireGuard IP Forwarding

I wanted WireGuard clients to access other devices on my home network, not just services running on the Raspberry Pi.

I checked the system's IPv4 forwarding setting:

```bash
sysctl net.ipv4.ip_forward
```

Initially, the output was:

```text
net.ipv4.ip_forward = 0
```

This meant IPv4 forwarding was disabled.

I enabled forwarding:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

To configure persistent forwarding, I used:

```text
/etc/sysctl.d/99-wireguard-forwarding.conf
```

With:

```ini
net.ipv4.ip_forward=1
```

This allows the Raspberry Pi to route IPv4 packets between network interfaces.

## 15. Network Address Translation

To allow VPN clients to communicate with home-network devices without requiring separate return routes, I configured NAT masquerading.

```bash
sudo iptables -t nat -A POSTROUTING \
  -s 10.8.0.0/24 \
  -d 192.168.1.0/24 \
  -o wlan0 \
  -j MASQUERADE
```

### Explanation

When a WireGuard client sends traffic to a home-network device, NAT translates the source address to the Raspberry Pi's LAN address.

For example:

```text
VPN Client
10.8.0.2
    |
    v
Raspberry Pi
10.8.0.1
    |
    | NAT Masquerading
    v
192.168.1.124
    |
    v
Home Network Device
192.168.1.x
```

This allows home-network devices to return responses through the Raspberry Pi without requiring them to know the WireGuard subnet.

## 16. VPN Forwarding Rules

I configured the FORWARD chain to allow VPN clients to access the home network.

### VPN to LAN

```bash
sudo iptables -A FORWARD \
  -i wg0 -o wlan0 \
  -s 10.8.0.0/24 \
  -d 192.168.1.0/24 \
  -j ACCEPT
```

### LAN to VPN Return Traffic

```bash
sudo iptables -A FORWARD \
  -i wlan0 -o wg0 \
  -s 192.168.1.0/24 \
  -d 10.8.0.0/24 \
  -m conntrack --ctstate ESTABLISHED,RELATED \
  -j ACCEPT
```

The first rule permits VPN clients to initiate connections to home-network devices.

The second rule permits established and related return traffic.

### Testing

I tested WireGuard access to other home-network devices after enabling IP forwarding and configuring NAT.

The VPN-to-LAN connection worked successfully.

This confirmed that the Raspberry Pi could route the tested traffic between the VPN and home network.

## 17. Firewall Verification

I used several commands to inspect the firewall.

### List Firewall Rules

```bash
sudo iptables -L INPUT -n -v --line-numbers
```

### View Rules in Command Format

```bash
sudo iptables -S
```

### Inspect NAT

```bash
sudo iptables -t nat -S
```

### Inspect nftables

```bash
sudo nft list ruleset
```

The nftables output confirmed that the IPv4 filter rules were managed through the iptables-nft compatibility layer.

### Check Listening Services

```bash
sudo ss -tulpn
```

This displayed services listening on ports including:

- TCP 22 — SSH
- TCP/UDP 53 — DNS
- TCP 80 — HTTP
- TCP 443 — HTTPS
- UDP 51820 — WireGuard

## 18. Firewall Backup and Rollback

Because I administered the Raspberry Pi remotely through SSH, I needed a way to recover if restrictive firewall rules interrupted connectivity.

I backed up my working configuration:

```bash
sudo iptables-save > /root/iptables-working.rules
```

I also explored using a temporary systemd timer to automatically restore the previous firewall configuration.

Example:

```bash
sudo systemd-run \
  --unit=firewall-rollback \
  --on-active=5m \
  /usr/sbin/iptables-restore /root/iptables-working.rules
```

The purpose of this rollback mechanism is to restore the previous firewall configuration if testing a restrictive policy causes a loss of connectivity.

To cancel a pending rollback after successful testing:

```bash
sudo systemctl stop firewall-rollback.timer
```

This introduced me to the importance of planning recovery procedures before making remote firewall changes.

## 19. Current Firewall Status

At the time of the last confirmed configuration, my IPv4 firewall policies were:

```text
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

The required service-specific allow rules had been configured.

However, because the default policies remained ACCEPT, unmatched IPv4 traffic was still allowed.

The firewall therefore had not yet reached a complete default-deny configuration.

The IPv6 firewall also remained unrestricted:

```text
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

Additional testing and configuration are required before considering the firewall fully hardened.

## 20. Security Considerations

### Principle of Least Privilege

Firewall rules should permit only the network traffic required for legitimate services.

### Remote Administration

SSH access should be restricted to trusted networks or authorized administrative devices.

### VPN Security

WireGuard provides encrypted communication and peer authentication.

Firewall rules provide an additional layer of control over which services and networks VPN clients can access.

### IPv6

IPv4 firewall rules do not automatically protect IPv6 traffic.

IPv6 filtering must be configured separately.

### Firewall Persistence

Rules added manually through `iptables` may not survive a reboot.

A persistence mechanism should be configured after the firewall has been tested.

### Recovery Planning

Restrictive firewall changes should be tested with a rollback mechanism to reduce the risk of losing remote administrative access.

## 21. Skills Demonstrated

- Linux firewall administration
- iptables rule configuration
- TCP/IP networking
- Connection tracking
- DNS traffic filtering
- VPN access control
- Network Address Translation
- IP forwarding
- Network troubleshooting
- SSH administration
- Firewall verification
- Technical documentation

## 22. Lessons Learned

Before this project, I had limited experience working directly with Linux firewall rules.

Configuring `iptables` helped me understand how network packets are processed and how firewall chains determine whether traffic is allowed or blocked.

I learned that simply creating ACCEPT rules does not make a firewall restrictive when the default policy already allows all traffic.

I also gained a better understanding of the difference between INPUT and FORWARD traffic.

For example, DNS requests sent to Pi-hole use the INPUT chain, while VPN traffic traveling through the Raspberry Pi to another home-network device uses the FORWARD chain.

Configuring NAT and IP forwarding helped me understand how devices on different private networks can communicate.

Another important lesson was the need to preserve SSH connectivity and prepare recovery procedures before making restrictive firewall changes.

## 23. Future Improvements

- Implement and validate default-deny INPUT and FORWARD policies.
- Configure appropriate IPv6 firewall restrictions.
- Restrict SSH access to specific administrative devices.
- Add logging for selected dropped packets.
- Make firewall rules persistent across reboots.
- Test firewall behavior after restarting WireGuard.
- Document blocked-connection tests and packet counters.
- Evaluate more granular access controls for VPN clients.

## 24. Conclusion

Implementing `iptables` expanded my Raspberry Pi homelab beyond DNS filtering and encrypted remote access.

This project gave me practical experience creating firewall rules, inspecting network traffic, configuring connection tracking, and managing communication between VPN clients and home-network devices.

The most valuable part of the project was learning how different firewall chains interact with services and routed traffic.

Although the final default-deny policy still requires validation, the work completed so far has strengthened my understanding of Linux networking, firewall administration, and defensive security.