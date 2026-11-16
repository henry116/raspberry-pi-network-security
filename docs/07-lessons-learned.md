# Lessons Learned — Raspberry Pi Network Security Homelab

## 1. Overview

Building my Raspberry Pi Network Security Homelab gave me an opportunity to apply cybersecurity and networking concepts in a practical environment.

Before starting this project, most of my experience came from coursework, TryHackMe, and independent learning.

Although I understood basic networking concepts, I wanted to gain experience configuring services, managing Linux systems, and troubleshooting problems without relying entirely on guided tutorials.

Throughout the project, I deployed Pi-hole, configured WireGuard VPN, and began implementing Linux firewall rules using `iptables`.

The project strengthened my understanding of network security, system administration, and troubleshooting.

## 2. Understanding DNS Beyond Theory

One of the biggest lessons I learned was how DNS works in an actual network environment.

Before working with Pi-hole, I primarily understood DNS as a service that translates domain names into IP addresses.

Deploying Pi-hole helped me understand the process in greater detail.

I learned how:

- Client devices generate DNS requests.
- DNS queries are sent to configured resolvers.
- Pi-hole checks requests against filtering rules.
- Allowed domains are resolved through upstream DNS services.
- Blocked domains receive filtering responses.
- DNS activity can be monitored through query logs.

Using the `dig` command helped me test DNS resolution directly rather than relying on whether a website loaded in my browser.

This improved my understanding of how DNS problems can be isolated and investigated.

## 3. Understanding DHCP and Network Configuration

One of the most memorable challenges occurred when I accidentally disabled DHCP on my Netgear router.

Although my Ubuntu laptop remained connected to Wi-Fi, it could no longer access the internet.

Initially, I did not fully understand why this happened.

After inspecting my network configuration, I discovered that the laptop had not received an IPv4 address or default gateway.

This helped me understand that being connected to a wireless network does not necessarily mean a device has the configuration needed to communicate with other networks.

I learned that:

- DHCP automatically assigns IP addresses and network settings.
- DNS resolves domain names.
- A DHCP reservation provides a consistent IP address.
- Incorrect router settings can affect multiple connected devices.

This experience reinforced the importance of understanding configuration changes before applying them.

## 4. Linux System Administration

The Raspberry Pi Zero W allowed me to practice administering a Linux system without a graphical desktop environment.

I managed the Raspberry Pi primarily through SSH.

Throughout the project, I worked with commands such as:

```bash
ip addr
ip route
ss
systemctl
sysctl
```

These tools helped me inspect network interfaces, identify listening services, manage system services, and configure kernel networking behavior.

I became more comfortable working through the Linux command line and understanding how services operate in the background.

## 5. Network Security Through DNS Filtering

Configuring Pi-hole helped me understand how DNS filtering can contribute to network security.

I learned that domain-based filtering can reduce access to known advertising, tracking, phishing, and potentially malicious infrastructure.

I also learned how to create custom denylist rules and verify that they work.

For example, I added `example.com` to Pi-hole's exact denylist and confirmed that the domain was blocked.

This demonstrated the importance of testing security controls rather than assuming they work after being configured.

I also learned that DNS filtering has limitations.

It cannot detect every malicious domain, inspect downloaded files for malware, or prevent applications from using alternative DNS resolvers.

This reinforced the concept of defense in depth.

## 6. WireGuard and Public-Key Authentication

Configuring WireGuard introduced me to encrypted VPN communication and public-key cryptography.

I learned that each WireGuard peer requires its own public and private key pair.

The private key must remain confidential, while the public key is shared with authorized peers.

I configured separate WireGuard clients for my iPhone and Ubuntu laptop.

This helped me understand:

- Public-key authentication
- VPN interfaces
- Tunnel IP addressing
- Peer configuration
- Encrypted communication
- Split tunneling
- Connection verification

I also learned that enabling a WireGuard interface does not automatically mean a VPN connection has been established.

Checking recent handshakes and testing actual network communication are important parts of verification.

## 7. Understanding Routing and NAT

One of the more technical parts of the project was configuring WireGuard clients to access other devices on my home network.

Initially, IPv4 forwarding was disabled on the Raspberry Pi.

I learned that a device must be configured to forward packets if it is going to route traffic between networks.

I enabled IPv4 forwarding and configured NAT masquerading.

This helped me understand how traffic moves between the WireGuard VPN subnet and my home LAN.

I also learned why return routing is important.

Without an appropriate return path, a device may receive a packet but be unable to send its response back to the original client.

Configuring NAT allowed my home-network devices to respond to VPN traffic through the Raspberry Pi.

## 8. Learning Linux Firewalls

Before this project, I had never configured `iptables` rules manually.

I learned how Linux firewalls use tables, chains, and rules to process network traffic.

The three chains I focused on were:

| Chain | Purpose |
|---|---|
| INPUT | Traffic destined for the Raspberry Pi |
| OUTPUT | Traffic originating from the Raspberry Pi |
| FORWARD | Traffic passing through the Raspberry Pi |

I also learned how firewall rules can match traffic based on:

- Source IP addresses
- Network interfaces
- TCP and UDP protocols
- Destination ports
- Connection states

Configuring rules for SSH, DNS, WireGuard, and VPN forwarding helped me understand how network access can be controlled.

One important lesson was that firewall rules must be considered together with their default policies.

Because my firewall initially used ACCEPT policies, unmatched traffic was still allowed.

This showed me why a firewall is not fully restrictive simply because several allow rules have been added.

## 9. The Importance of Troubleshooting

One of the biggest takeaways from this project was learning how to troubleshoot problems systematically.

When something stopped working, I learned to investigate the configuration instead of immediately reinstalling software or resetting devices.

My troubleshooting process became:

1. Identify the problem.
2. Check the current configuration.
3. Determine which component may be responsible.
4. Test one possible cause at a time.
5. Apply a change.
6. Verify whether the change resolved the issue.
7. Document the result.

This approach helped me better understand the relationship between networking services.

It also made me more comfortable working through unfamiliar technical problems.

## 10. Security and Configuration Management

Working with WireGuard and firewall rules taught me the importance of protecting sensitive configuration information.

For example, WireGuard private keys should never be uploaded to a public GitHub repository.

I also learned that firewall changes can interrupt remote administration if they are applied incorrectly.

This introduced me to the importance of:

- Restricting access to sensitive files
- Reviewing configurations before publishing
- Backing up working firewall rules
- Planning rollback procedures
- Testing changes before making them permanent

These practices are important when administering systems that provide network services.

## 11. Technical Documentation

Another important skill I developed was documenting my work.

I created a GitHub repository to organize my project into separate sections covering:

- Project overview
- Network architecture
- Pi-hole installation
- WireGuard configuration
- Testing and validation
- Troubleshooting
- Lessons learned
- Firewall hardening

Writing documentation helped me better understand the technologies I was using.

It also encouraged me to explain not only what commands I executed but why they were necessary and what results they produced.

## 12. What I Would Improve

If I were to rebuild this homelab, I would make several improvements.

### Plan the Network Before Making Changes

I would document the existing IP addresses, DHCP configuration, and DNS settings before modifying the router.

This would make troubleshooting easier if something stopped working.

### Test Services Individually

I would verify Pi-hole, WireGuard, and firewall rules independently before integrating them.

This would help isolate problems and reduce the number of possible causes when troubleshooting.

### Implement Monitoring

I would add monitoring to detect when Pi-hole or WireGuard becomes unavailable.

This would improve visibility into service health.

### Improve Firewall Hardening

I would complete the default-deny firewall configuration, implement IPv6 restrictions, and verify that the rules persist after reboot.

### Evaluate DNS Redundancy

I would investigate ways to maintain DNS availability if the Raspberry Pi becomes unavailable.

Because Pi-hole is used as a DNS resolver, its availability can affect devices that depend on it.

## 13. Skills Developed

Through this project, I developed practical experience with:

- Linux system administration
- DNS configuration and troubleshooting
- DHCP and IP addressing
- Router configuration
- Network security monitoring
- WireGuard VPN
- Public-key authentication
- IPv4 routing
- Network Address Translation
- Linux firewall configuration
- SSH administration
- Troubleshooting
- Technical documentation

## 14. Conclusion

Building this homelab was one of my most valuable hands-on cybersecurity learning experiences.

It helped me move beyond understanding networking concepts in theory and apply them to real systems.

The most valuable part was not simply getting Pi-hole or WireGuard running, but learning how to troubleshoot problems when configurations did not work as expected.

Through this project, I gained a stronger understanding of DNS, DHCP, VPNs, routing, NAT, and Linux firewalls.

I plan to continue improving the homelab by strengthening its firewall configuration, adding monitoring, and exploring additional defensive security tools.