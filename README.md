# Raspberry Pi Network Security Homelab

## Overview

This project documents my experience deploying Pi-hole DNS filtering and configuring WireGuard VPN on a Raspberry Pi to gain hands-on experience with network security, Linux administration, and troubleshooting.

The goal was to understand how network services work together and how DNS filtering and encrypted remote access can improve the security of a home network.

## Technologies Used

- Raspberry Pi
- Linux
- Pi-hole
- WireGuard
- DNS
- SSH
- Firewall rules
- Git and GitHub

## Project Objectives

1. Deploy Pi-hole for network-wide DNS filtering.
2. Configure router-level DNS settings to direct requests to Pi-hole.
3. Monitor allowed and blocked DNS queries.
4. Configure WireGuard for encrypted remote access.
5. Troubleshoot connectivity and DNS resolution problems.
6. Document implementation steps and lessons learned.

## Network Architecture

```text
Home Network Devices
        |
        v
    Home Router
        |
        v
     Pi-hole
        |
   DNS Filtering
        |
   +----+----+
   |         |
 Blocked   Allowed
             |
             v
       Upstream DNS
```

## Implementation

### Pi-hole DNS Filtering

Deployed Pi-hole on a Raspberry Pi and configured the home network to use it as a DNS filtering service.

Pi-hole evaluates domain requests against configured blocklists and prevents blocked domains from resolving normally.

### DNS Monitoring

Used the Pi-hole dashboard to examine DNS requests, blocked domains, and device activity.

### WireGuard VPN

Configured WireGuard to explore encrypted remote access and public-key authentication.

### Troubleshooting

Investigated DNS configuration and network connectivity issues while integrating the Raspberry Pi with the home router.

## Skills Demonstrated

- DNS configuration and troubleshooting
- Linux system administration
- Network security monitoring
- VPN fundamentals
- Firewall configuration
- Technical documentation

## Lessons Learned

This project helped me understand DNS resolution beyond classroom explanations. I gained practical experience configuring network services and troubleshooting connectivity issues.

It also reinforced the importance of validating network changes because incorrect DNS or routing configurations can disrupt connectivity for multiple devices.

## Future Improvements

- Add service availability monitoring.
- Document DNS filtering tests with screenshots.
- Evaluate additional blocklists.
- Improve network security documentation.
- Explore redundant DNS configurations.

## Security Notice

This repository is intended for educational and portfolio purposes. Private IP addresses, VPN private keys, authentication credentials, and other sensitive configuration details should be removed or replaced with placeholders before publishing.