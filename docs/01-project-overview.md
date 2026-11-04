# Project Overview — Raspberry Pi Network Security Homelab

## 1. Introduction

This project documents my experience building a network security homelab using a Raspberry Pi Zero W, Pi-hole, and Linux.

I wanted to gain hands-on experience with network administration and cybersecurity by configuring services on my own home network rather than relying entirely on guided tutorials.

My primary focus was understanding how DNS resolution works, how network-level filtering can be implemented, and how network configuration changes affect connected devices.

I also wanted to strengthen my Linux administration, troubleshooting, and technical documentation skills.

## 2. Project Motivation

Before starting this project, most of my networking knowledge came from coursework, TryHackMe, and independent learning.

Although I understood that DNS translates domain names into IP addresses, I wanted to understand how DNS requests are processed in a real network environment.

Deploying Pi-hole gave me an opportunity to configure a DNS service, analyze DNS queries, and test domain-blocking policies.

I also wanted to gain more experience managing a Linux system remotely through SSH and troubleshooting networking issues independently.

## 3. Project Objectives

The main objectives were:

1. Deploy Pi-hole on a Raspberry Pi Zero W.
2. Configure a consistent IP address using DHCP reservation.
3. Configure the home router to forward DNS queries to Pi-hole.
4. Monitor DNS requests using Pi-hole's dashboard.
5. Implement and test custom domain-blocking rules.
6. Troubleshoot network connectivity and DNS resolution problems.
7. Document the implementation and results on GitHub.

An additional goal of the broader homelab project is exploring encrypted remote access using WireGuard VPN.

## 4. Hardware and Software

| Component | Description |
|---|---|
| Raspberry Pi | Raspberry Pi Zero W Rev 1.1 |
| Operating System | Raspberry Pi OS 13 (Trixie) |
| Router | Netgear R7960P |
| Raspberry Pi IP | `192.168.1.124` |
| Router IP | `192.168.1.1` |
| Network Interface | `wlan0` |
| Client | Ubuntu Linux laptop |
| DNS Filtering | Pi-hole |
| Remote Administration | SSH |
| Testing Tool | `dig` |
| Documentation | Git and GitHub |

## 5. Project Scope

### Pi-hole DNS Filtering

The primary component of this project is Pi-hole, which provides DNS filtering for devices using it as their DNS resolver.

Pi-hole checks requested domains against configured filtering rules.

Requests matching blocking rules are denied, while allowed requests are resolved through an upstream DNS resolver.

### Network Configuration

I configured a DHCP reservation on my Netgear router to provide the Raspberry Pi with a consistent IP address.

I also configured the router's upstream DNS settings to use Pi-hole.

This allowed me to explore how DHCP, DNS, and router configurations interact.

### DNS Monitoring and Testing

I used Pi-hole's dashboard and Query Log to monitor DNS activity.

I also used the `dig` utility to test DNS resolution directly against the Raspberry Pi.

To validate DNS filtering, I created an exact denylist entry for `example.com` and confirmed that the request was blocked in Pi-hole's Query Log.

### WireGuard VPN

WireGuard is part of my broader network security learning. I have previously worked with WireGuard to explore encrypted remote access and public-key authentication.

The current documentation focuses on the Pi-hole deployment. WireGuard configuration and validation will be documented separately.

## 6. Implementation Results

The following outcomes were achieved:

- Installed Pi-hole on a Raspberry Pi Zero W.
- Configured a DHCP reservation for `192.168.1.124`.
- Configured the Netgear router to use Pi-hole as its upstream DNS server.
- Successfully resolved domains through Pi-hole using `dig`.
- Monitored DNS queries through Pi-hole's Query Log.
- Created and enabled a custom exact-deny rule.
- Verified that Pi-hole blocked a DNS request for `example.com`.
- Restored network connectivity after encountering a DHCP configuration issue.

These results demonstrate basic DNS service deployment, network configuration, DNS monitoring, and security-control validation.

## 7. Challenges Encountered

One of the biggest challenges occurred while configuring the Netgear router.

I accidentally disabled the router's DHCP server while attempting to configure Pi-hole.

As a result, my Ubuntu laptop remained connected to Wi-Fi but could not obtain an IPv4 address or access the internet.

I investigated the issue using Linux networking commands, including:

```bash
ip -br addr
ip route
```

After identifying the DHCP configuration issue, I restored the router's DHCP functionality and configured a DHCP reservation for the Raspberry Pi.

This experience helped me better understand the difference between DNS and DHCP and the importance of validating network changes.

## 8. Skills Developed

Through this project, I gained practical experience with:

- Linux system administration
- DNS resolution and filtering
- DHCP configuration
- Router administration
- IP addressing and subnetting
- SSH remote administration
- DNS query monitoring
- Security policy testing
- Network troubleshooting
- Technical documentation

## 9. Future Improvements

Potential improvements include:

- Implementing DNS service availability monitoring.
- Testing additional domain-filtering policies.
- Evaluating different blocklists.
- Documenting WireGuard VPN configuration and connectivity tests.
- Exploring DNS redundancy.
- Improving network segmentation and firewall policies.

## 10. Conclusion

Building this homelab helped me apply networking and cybersecurity concepts in a practical environment.

Rather than simply learning what DNS and DHCP do, I gained experience configuring these services, testing their behavior, and troubleshooting problems when something went wrong.

The most valuable part of this project was learning how to investigate configuration issues and understand their impact on network connectivity.

This project strengthened my interest in network security and defensive cybersecurity while giving me practical experience that I can continue building on.