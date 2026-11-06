# Network Architecture

## 1. Overview

This document explains the network architecture of my Raspberry Pi Network Security Homelab.

The project combines Pi-hole DNS filtering and WireGuard VPN on a Raspberry Pi Zero W to provide network-level DNS filtering, DNS query monitoring, and encrypted remote access.

The Raspberry Pi acts as a dedicated host for both services, while my Netgear router manages the home network and assigns IP addresses through DHCP.

The goal was to understand how DNS, DHCP, routing, and VPN technologies work together in a real network environment.

## 2. Network Components

| Component | Device / Technology | Purpose |
|---|---|---|
| Router | Netgear R7960P | Home network gateway and DHCP server |
| Server | Raspberry Pi Zero W | Hosts Pi-hole and WireGuard |
| Operating System | Raspberry Pi OS 13 (Trixie) | Linux server environment |
| DNS Filtering | Pi-hole | Filters DNS queries using blocklists |
| VPN Server | WireGuard | Provides encrypted VPN connectivity |
| Client 1 | Ubuntu Laptop | DNS testing and VPN client |
| Client 2 | iPhone | Mobile VPN client |
| Remote Administration | SSH | Secure command-line access |
| DNS Testing | `dig` | Verifies DNS resolution and filtering |

## 3. IP Addressing

The home network uses the private IPv4 subnet `192.168.1.0/24`.

| Device | IP Address |
|---|---|
| Netgear Router | `192.168.1.1` |
| Raspberry Pi | `192.168.1.124` |
| Home Network | `192.168.1.0/24` |
| WireGuard Server | `10.8.0.1/24` |
| iPhone VPN Client | `10.8.0.2/32` |
| Ubuntu VPN Client | `10.8.0.3/32` |
| WireGuard VPN Network | `10.8.0.0/24` |

The Raspberry Pi receives a consistent local IP address through a DHCP reservation configured on the Netgear router.

WireGuard uses a separate private subnet to distinguish VPN traffic from the local home network.

## 4. Network Topology

```text
                         INTERNET
                            |
                            |
                     NETGEAR R7960P
                       192.168.1.1
                            |
                   HOME NETWORK (LAN)
                      192.168.1.0/24
                            |
                 +----------+----------+
                 |                     |
                 v                     v
           Ubuntu Laptop        Raspberry Pi Zero W
                                  192.168.1.124
                                        |
                              +---------+---------+
                              |                   |
                              v                   v
                           Pi-hole             WireGuard
                        DNS Filtering         VPN Server
                                                10.8.0.1
                                                   |
                                          +--------+--------+
                                          |                 |
                                          v                 v
                                        iPhone            Ubuntu
                                       10.8.0.2          10.8.0.3
```

The Raspberry Pi hosts both Pi-hole and WireGuard.

Pi-hole handles DNS requests directed to the Raspberry Pi, while WireGuard provides encrypted communication between authorized VPN clients and the server.

## 5. DHCP Architecture

Dynamic Host Configuration Protocol (DHCP) automatically provides network configuration information to connected devices.

The Netgear router is responsible for DHCP.

### DHCP Configuration

| Setting | Value |
|---|---|
| DHCP Server | Netgear R7960P |
| Router IP | `192.168.1.1` |
| DHCP Starting Address | `192.168.1.100` |
| DHCP Ending Address | `192.168.1.200` |
| Raspberry Pi Reserved Address | `192.168.1.124` |

### DHCP Process

```text
Client connects to network
          |
          v
Client requests network configuration
          |
          v
Netgear DHCP Server
          |
          v
Assigns IP address and network settings
          |
          v
Client connects to network
```

The DHCP reservation ensures that the Raspberry Pi receives the same IP address when requesting network configuration.

This is important because devices need a consistent address to reach Pi-hole.

## 6. DNS Architecture

Domain Name System (DNS) translates domain names into IP addresses.

Pi-hole provides DNS filtering by checking requested domains against configured blocklists and custom filtering rules.

### DNS Request Flow

```text
Ubuntu Laptop
      |
      | DNS Query
      v
Netgear Router
192.168.1.1
      |
      | DNS Forwarding
      v
Pi-hole
192.168.1.124
      |
      | Check Filtering Rules
      v
 +-----------+-----------+
 |                       |
 v                       v
Blocked                Allowed
 |                       |
 v                       v
Blocking Response     Upstream DNS
                         |
                         v
                    DNS Response
```

The Netgear router was configured to use Pi-hole as its upstream DNS resolver.

Some devices may also query Pi-hole directly.

Pi-hole processes DNS requests and determines whether a domain should be allowed or blocked.

### DNS Filtering

If a requested domain matches a configured blocking rule, Pi-hole returns a blocking response.

If the domain is allowed, Pi-hole resolves the request using its configured upstream DNS resolver.

## 7. WireGuard VPN Architecture

WireGuard provides encrypted VPN connectivity using public-key cryptography.

The Raspberry Pi acts as the WireGuard server, while the iPhone and Ubuntu laptop act as clients.

### VPN Configuration

| Setting | Value |
|---|---|
| VPN Protocol | WireGuard |
| Transport | UDP |
| Listening Port | `51820` |
| VPN Interface | `wg0` |
| Server VPN Address | `10.8.0.1` |
| iPhone Address | `10.8.0.2` |
| Ubuntu Address | `10.8.0.3` |

### VPN Connection Flow

```text
iPhone / Ubuntu Laptop
          |
          | Encrypted WireGuard Tunnel
          v
       Internet
          |
          v
     Netgear Router
          |
          | UDP 51820
          v
   Raspberry Pi Zero W
          |
          v
       WireGuard
        10.8.0.1
          |
          +------ Pi-hole DNS
          |
          +------ Home Network
```

WireGuard uses unique public and private key pairs to authenticate peers.

Each client has a separate VPN address and key pair.

This allows individual devices to be authorized or removed without changing the credentials of other clients.

## 8. Split Tunneling

I configured WireGuard clients with split-tunnel routing.

The client configuration includes:

```ini
AllowedIPs = 10.8.0.0/24, 192.168.1.0/24
```

This directs traffic destined for the VPN subnet and home LAN through the WireGuard tunnel.

Other internet traffic continues using the client's normal network connection.

This configuration allows remote clients to access selected home-network resources without routing all internet traffic through the VPN.

## 9. Pi-hole and WireGuard Integration

The Raspberry Pi hosts both the DNS filtering service and the VPN server.

WireGuard clients are configured to use the Raspberry Pi's VPN address for DNS:

```ini
DNS = 10.8.0.1
```

This allows clients to send DNS requests to Pi-hole through the encrypted VPN tunnel when Pi-hole is configured to accept those requests.

### DNS Over VPN

```text
Remote VPN Client
       |
       | Encrypted Tunnel
       v
WireGuard Server
    10.8.0.1
       |
       v
Pi-hole DNS
       |
       | Check Filtering Rules
       v
Allowed / Blocked
```

This configuration combines encrypted remote connectivity with DNS filtering.

## 10. Security Considerations

Several security considerations were important when designing the network.

### Public-Key Authentication

WireGuard uses unique cryptographic key pairs for each peer.

Private keys must remain confidential.

### Network Segmentation

The WireGuard subnet is separate from the home LAN subnet.

This provides logical separation between VPN clients and local devices, although additional firewall rules are required to enforce access restrictions.

### DNS Filtering

Pi-hole provides an additional layer of protection by blocking configured domains.

However, DNS filtering does not replace endpoint security or other network protections.

### Limited Port Exposure

Remote WireGuard access requires the VPN endpoint to be reachable.

Only necessary services should be exposed to the internet.

The Pi-hole administration interface should not be publicly exposed.

## 11. Conclusion

This network architecture combines DNS filtering, DHCP configuration, and encrypted VPN connectivity on a Raspberry Pi Zero W.

Building the environment helped me understand how network services interact and how IP addressing, routing, and DNS configuration affect connectivity.

The project also provided practical experience designing and documenting a small network security environment.