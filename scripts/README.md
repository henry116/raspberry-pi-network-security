# Raspberry Pi Firewall Automation

## Overview

This project documents a Bash script I developed to automate IPv4 firewall configuration on my Raspberry Pi Zero W.

The Raspberry Pi hosts Pi-hole for DNS filtering and WireGuard for encrypted VPN access. As I added more services to my homelab, I wanted to learn how to control network traffic using Linux firewall rules.

Rather than manually entering individual `iptables` commands, I created a script that organizes firewall rules, backs up existing configurations, and provides a rollback mechanism for testing restrictive policies.

The script is designed specifically for my Raspberry Pi homelab and is not intended to be a universal firewall configuration.

## Technologies Used

| Technology | Purpose |
|---|---|
| Bash | Firewall automation and scripting |
| iptables | IPv4 packet filtering |
| nftables | Firewall backend through iptables-nft |
| Linux systemd | Timed firewall rollback |
| Pi-hole | DNS filtering |
| WireGuard | Encrypted VPN connectivity |
| Raspberry Pi OS 13 (Trixie) | Linux operating system |
| SSH | Remote administration |
| NAT | Network Address Translation |

## Project Objectives

The main objectives of this project were to:

1. Automate firewall configuration using Bash.
2. Apply the principle of least privilege to incoming network connections.
3. Restrict SSH administration to the home network.
4. Allow Pi-hole DNS requests from authorized networks.
5. Allow WireGuard VPN connections.
6. Enable VPN clients to access devices on the home LAN.
7. Implement a default-deny policy for unmatched incoming and forwarded IPv4 traffic.
8. Back up existing firewall rules before making changes.
9. Provide automatic rollback protection during testing.
10. Document firewall configuration and verification procedures.

## Network Configuration

The script uses the following network configuration:

| Component | Configuration |
|---|---|
| Raspberry Pi | `192.168.1.124` |
| Home Router | `192.168.1.1` |
| LAN Interface | `wlan0` |
| LAN Subnet | `192.168.1.0/24` |
| WireGuard Interface | `wg0` |
| WireGuard Server | `10.8.0.1` |
| VPN Subnet | `10.8.0.0/24` |

These values are specific to my homelab and must be modified before using the script on another network.

## Firewall Architecture

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
       TCP/UDP 53           UDP 51820
           |                   |
           |                   v
           |              VPN Clients
           |              10.8.0.0/24
           |                   |
           +---------+---------+
                     |
                     v
               Home Network
              192.168.1.0/24
```

The firewall controls traffic destined for the Raspberry Pi and traffic forwarded between WireGuard clients and the home network.

## Firewall Rules

The script configures the following IPv4 access policies:

| Service | Protocol / Port | Allowed Source |
|---|---|---|
| SSH | TCP 22 | Home LAN |
| Pi-hole DNS | TCP/UDP 53 | Home LAN |
| Pi-hole DNS over VPN | TCP/UDP 53 | WireGuard subnet |
| Pi-hole Dashboard | TCP 80/443 | Home LAN |
| WireGuard VPN | UDP 51820 | Any source |
| DHCP Responses | UDP 67 → 68 | Incoming on `wlan0` |
| ICMP Echo Requests | ICMP | Home LAN and VPN |
| VPN-to-LAN Forwarding | IPv4 | WireGuard subnet |
| Established Connections | Connection tracking | Allowed |

### Default Firewall Policies

The script applies:

```text
INPUT   DROP
FORWARD DROP
OUTPUT  ACCEPT
```

**INPUT:** Blocks incoming IPv4 traffic unless an explicit rule allows it.

**FORWARD:** Blocks forwarded IPv4 traffic unless an explicit rule allows it.

**OUTPUT:** Allows outbound IPv4 traffic initiated by the Raspberry Pi.

The default-deny policy reduces the number of services accessible to unauthorized sources.

## Script Features

### 1. Root Privilege Verification

The script checks whether it is running with root privileges.

Firewall modifications require administrative access.

```bash
if [[ "$EUID" -ne 0 ]]; then
    echo "[ERROR] Run with sudo."
    exit 1
fi
```

### 2. Dry-Run Mode

The script supports previewing the proposed firewall configuration without modifying the active rules.

```bash
./firewall.sh --dry-run
```

This allows the user to review the rules before applying them.

### 3. Firewall Backup

Before applying changes, the script saves the existing IPv4 firewall configuration.

```bash
iptables-save > /root/firewall-backups/iptables-before-apply.rules
```

This backup can be used to restore the previous configuration if necessary.

### 4. Automatic Rollback

Because the Raspberry Pi is administered remotely through SSH, restrictive firewall changes could interrupt access.

To reduce this risk, the script schedules an automatic rollback using `systemd-run`.

The rollback is scheduled to restore the previous IPv4 firewall configuration after five minutes.

If testing succeeds, the rollback timer can be canceled.

### 5. Pi-hole DNS Rules

The script permits DNS traffic from the home LAN and WireGuard subnet.

Both TCP and UDP port 53 are allowed.

This enables Pi-hole to continue processing authorized DNS requests while unmatched incoming traffic is blocked.

### 6. WireGuard VPN Rules

The script allows incoming WireGuard connections on UDP port 51820.

It also configures forwarding rules that permit VPN clients to access the home network.

### 7. NAT Masquerading

The script configures NAT masquerading for VPN traffic destined for the home LAN.

```bash
iptables -t nat -A POSTROUTING \
    -s 10.8.0.0/24 \
    -d 192.168.1.0/24 \
    -o wlan0 \
    -j MASQUERADE
```

This allows home-network devices to respond to VPN clients through the Raspberry Pi without requiring separate routes to the VPN subnet.

## Installation and Usage

### Step 1: Clone the Repository

```bash
git clone git@github.com:henry116/raspberry-pi-network-security.git

cd raspberry-pi-network-security/scripts
```

### Step 2: Make the Script Executable

```bash
chmod +x firewall.sh
```

### Step 3: Check Bash Syntax

```bash
bash -n firewall.sh
```

If no errors are reported, Bash has not detected any syntax errors.

### Step 4: Preview Firewall Rules

```bash
./firewall.sh --dry-run
```

This displays the proposed IPv4 firewall configuration without applying it.

### Step 5: Review the Existing Firewall

Before applying the script:

```bash
sudo iptables -S
sudo iptables -t nat -S
```

The script replaces the active IPv4 filter and NAT tables. Existing rules managed by other applications may be affected.

Verify that the proposed configuration preserves all required services.

### Step 6: Apply the Firewall

**Warning:** Applying firewall rules remotely can interrupt SSH, DNS, or VPN connectivity. Keep an existing SSH session open and ensure that a recovery method is available.

```bash
sudo ./firewall.sh --apply
```

The script:

1. Checks root privileges.
2. Verifies that `iptables` is installed.
3. Validates the proposed ruleset.
4. Backs up the current IPv4 rules.
5. Schedules a five-minute rollback.
6. Applies the new firewall configuration.

### Step 7: Verify Connectivity

Immediately test the following services.

**SSH:**

```bash
ssh hcpark@192.168.1.124
```

**Pi-hole DNS:**

```bash
dig @192.168.1.124 google.com
```

**DNS over TCP:**

```bash
dig +tcp @192.168.1.124 google.com
```

**WireGuard:**

```bash
sudo wg show
```

**VPN-to-LAN access:**

Connect through WireGuard from an external network and verify access to an authorized home-network device.

Also verify that the Pi-hole dashboard remains accessible from the home LAN.

### Step 8: Confirm the Configuration

If all services continue working:

```bash
sudo ./firewall.sh --confirm
```

This cancels the pending rollback timer.

If testing fails, do not confirm the configuration. Allow the rollback timer to restore the previous IPv4 firewall rules.

## Firewall Verification Commands

| Command | Purpose |
|---|---|
| `sudo iptables -S` | Display IPv4 firewall rules |
| `sudo iptables -L -n -v` | Inspect firewall rules and counters |
| `sudo iptables -t nat -S` | Inspect NAT rules |
| `sudo iptables-save` | Export the active IPv4 ruleset |
| `sudo wg show` | Check WireGuard peer status |
| `ip -br addr` | Display network interfaces |
| `sysctl net.ipv4.ip_forward` | Verify IPv4 forwarding |
| `sudo ss -tulpn` | Identify listening network services |

## Security Considerations

### Least Privilege

Only required services should be accessible from authorized networks.

### SSH Protection

SSH access is restricted to the home LAN by the IPv4 firewall configuration.

### VPN Authentication

WireGuard uses public-key authentication to identify authorized VPN peers.

### Configuration Backups

Existing firewall rules are backed up before applying a restrictive configuration.

### Recovery Planning

A timed rollback helps reduce the risk of losing remote access during firewall testing.

### IPv6 Limitations

The current script only manages IPv4 rules.

IPv6 traffic is not restricted by this script. A separate IPv6 firewall policy is required for complete dual-stack protection.

### Firewall Persistence

The script does not automatically save the new rules across reboots.

Persistence should only be configured after successful testing.

### IP Forwarding

VPN-to-LAN routing requires IPv4 forwarding to be enabled separately.

Verify using:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

## Current Project Status

The script has been developed to automate the IPv4 firewall configuration for my Raspberry Pi homelab.

The following features are implemented in the script:

- Firewall rule generation
- Default-deny INPUT and FORWARD policies
- SSH and DNS access rules
- WireGuard VPN access rules
- VPN forwarding and NAT
- Firewall backup
- Timed rollback
- Dry-run mode

**Deployment status:** The automated script's complete application, rollback, and reboot behavior still require validation. These features should not be considered production-tested until the corresponding tests have been completed.

## Future Improvements

- Add IPv6 firewall configuration.
- Implement persistent firewall rules.
- Add logging for dropped packets.
- Restrict SSH to specific administrative devices.
- Add automated connectivity tests.
- Improve rollback and recovery handling.
- Test firewall behavior after reboot.
- Add unit tests for Bash functions.
- Evaluate `nftables` as an alternative to the `iptables` compatibility interface.

## Lessons Learned

Developing this script helped me better understand how Linux firewalls can be configured and automated using Bash.

I learned how firewall chains, connection tracking, and NAT interact with network services.

I also gained experience organizing Bash scripts into reusable functions and implementing safety mechanisms for potentially disruptive system changes.

One of the most important lessons was that firewall automation requires more than simply creating rules. Changes must be validated, tested, and recoverable, especially when administering systems remotely.

## Conclusion

This project expands my Raspberry Pi Network Security Homelab by introducing automated firewall configuration.

The script brings together Linux system administration, Bash scripting, network security, VPN routing, and firewall management.

It also provides a foundation for future improvements involving IPv6 filtering, automated testing, logging, and persistent firewall configuration.
