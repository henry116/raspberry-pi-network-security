# WireGuard VPN Configuration

## 1. Project Overview

As part of my Raspberry Pi Network Security Homelab, I configured WireGuard VPN on my Raspberry Pi Zero W to provide encrypted remote access to my home network.

My goal was to understand how virtual private networks (VPNs) work, how public-key authentication is implemented, and how encrypted tunnels can be used to securely communicate with devices on a private network.

I also wanted to integrate WireGuard with my existing Pi-hole DNS filtering service so that authorized devices could use my home DNS filtering system while connected through the VPN.

## 2. Project Objectives

The main objectives of this implementation were:

1. Install and configure WireGuard on a Raspberry Pi Zero W.
2. Generate unique public and private key pairs for the VPN server and clients.
3. Configure the Raspberry Pi as a WireGuard VPN server.
4. Configure an iPhone and Ubuntu laptop as VPN clients.
5. Establish encrypted VPN tunnels between clients and the Raspberry Pi.
6. Configure VPN clients to use Pi-hole for DNS resolution.
7. Verify successful VPN connections using WireGuard monitoring commands.

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| Raspberry Pi Zero W | Hosts the WireGuard VPN server |
| Raspberry Pi OS 13 (Trixie) | Linux operating system |
| WireGuard | Encrypted VPN connectivity |
| Pi-hole | DNS filtering |
| Ubuntu Linux | VPN client |
| iPhone | Mobile VPN client |
| SSH | Remote Raspberry Pi administration |
| Netgear R7960P | Router and network configuration |
| UDP | Transport protocol used by WireGuard |

## 4. Network Architecture

The Raspberry Pi hosts both Pi-hole and WireGuard.

The VPN uses a separate private subnet to distinguish VPN clients from devices on the home network.

```text
                 REMOTE CLIENTS
                (iPhone / Ubuntu)
                       |
                       |
                WireGuard VPN
                 UDP 51820
                       |
                       v
                  INTERNET
                       |
                       v
                 NETGEAR ROUTER
                  192.168.1.1
                       |
                       v
                RASPBERRY PI ZERO W
                   192.168.1.124
                       |
              +--------+--------+
              |                 |
              v                 v
          WireGuard           Pi-hole
           10.8.0.1         DNS Filtering
              |
       +------+------+
       |             |
       v             v
     iPhone        Ubuntu
    10.8.0.2      10.8.0.3
```

### Network Configuration

| Component | IP Address / Configuration |
|---|---|
| Netgear Router | `192.168.1.1` |
| Raspberry Pi | `192.168.1.124` |
| WireGuard Interface | `wg0` |
| WireGuard Server | `10.8.0.1/24` |
| iPhone Client | `10.8.0.2/32` |
| Ubuntu Client | `10.8.0.3/32` |
| WireGuard Port | UDP `51820` |
| VPN Subnet | `10.8.0.0/24` |

## 5. WireGuard Installation

I installed WireGuard using the Raspberry Pi OS package manager.

```bash
sudo apt update
sudo apt install wireguard -y
```

After installation, I verified the installed version:

```bash
wg --version
```

I also checked whether the Linux kernel supported WireGuard:

```bash
sudo modprobe wireguard
```

This helped verify that the operating system could support the WireGuard VPN interface.

## 6. Public-Key Authentication

WireGuard uses public-key cryptography to authenticate VPN peers.

Each device requires its own unique public and private key pair.

I generated separate key pairs for the Raspberry Pi server, iPhone, and Ubuntu laptop.

### Server Key Generation

```bash
sudo install -d -m 700 /etc/wireguard

sudo sh -c 'umask 077; wg genkey > /etc/wireguard/server_private.key'

sudo sh -c 'wg pubkey < /etc/wireguard/server_private.key > /etc/wireguard/server_public.key'
```

### Understanding the Keys

**Private Key**
- Must remain confidential.
- Used by the device as part of WireGuard's cryptographic authentication and key agreement.
- Should never be uploaded to GitHub.

**Public Key**
- Derived from the private key.
- Shared with authorized WireGuard peers.
- Used to identify and authenticate the corresponding peer.

Each VPN client uses a unique key pair so that the server can distinguish between authorized devices.

## 7. WireGuard Server Configuration

I configured the Raspberry Pi's WireGuard interface using:

`/etc/wireguard/wg0.conf`

The following is a sanitized example of the configuration.

```ini
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <SERVER_PRIVATE_KEY>

[Peer]
# iPhone
PublicKey = <IPHONE_PUBLIC_KEY>
AllowedIPs = 10.8.0.2/32

[Peer]
# Ubuntu Laptop
PublicKey = <UBUNTU_PUBLIC_KEY>
AllowedIPs = 10.8.0.3/32
```

### Configuration Explanation

| Setting | Purpose |
|---|---|
| `Address` | Assigns the VPN server's tunnel IP address |
| `ListenPort` | Defines the UDP port used by WireGuard |
| `PrivateKey` | Identifies the server cryptographically |
| `[Peer]` | Defines an authorized VPN client |
| `PublicKey` | Identifies the authorized client |
| `AllowedIPs` | Associates permitted tunnel addresses with each peer |

The iPhone and Ubuntu laptop were configured with different tunnel addresses to prevent IP address conflicts.

## 8. Starting the WireGuard Service

I used systemd to manage the WireGuard interface.

```bash
sudo systemctl start wg-quick@wg0
```

To enable the interface automatically at startup:

```bash
sudo systemctl enable wg-quick@wg0
```

I verified the service status:

```bash
sudo systemctl status wg-quick@wg0
```

The service may display:

`active (exited)`

This is normal because `wg-quick` configures the network interface and then exits while the interface remains active.

I also verified the interface:

```bash
ip -br addr show wg0
```

## 9. iPhone Client Configuration

I configured my iPhone as the first WireGuard VPN client.

The iPhone was assigned:

`10.8.0.2/32`

I generated a unique key pair and created a client configuration.

### Sanitized iPhone Configuration

```ini
[Interface]
PrivateKey = <IPHONE_PRIVATE_KEY>
Address = 10.8.0.2/32
DNS = 10.8.0.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <PUBLIC_IP_OR_HOSTNAME>:51820
AllowedIPs = 10.8.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

### Configuration Import

I used the `qrencode` utility to import the configuration into the WireGuard iPhone application.

```bash
sudo apt install qrencode -y
```

```bash
sudo qrencode -t ansiutf8 < /etc/wireguard/iphone.conf
```

The QR code contained the iPhone's VPN configuration, including its private key.

For security reasons, I did not publish the QR code or private key.

## 10. Ubuntu Client Configuration

I configured my Ubuntu laptop as the second WireGuard client.

The laptop was assigned:

`10.8.0.3/32`

Unlike the iPhone configuration, I generated the Ubuntu key pair directly on the laptop.

### Ubuntu Key Generation

```bash
sudo install -d -m 700 /etc/wireguard

sudo sh -c 'umask 077; wg genkey > /etc/wireguard/ubuntu_private.key'

sudo sh -c 'wg pubkey < /etc/wireguard/ubuntu_private.key > /etc/wireguard/ubuntu_public.key'
```

I added the Ubuntu public key to the Raspberry Pi server configuration.

### Sanitized Ubuntu Configuration

```ini
[Interface]
PrivateKey = <UBUNTU_PRIVATE_KEY>
Address = 10.8.0.3/32
DNS = 10.8.0.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <PUBLIC_IP_OR_HOSTNAME>:51820
AllowedIPs = 10.8.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

I secured the configuration file:

```bash
sudo chmod 600 /etc/wireguard/wg0.conf
```

Then started the tunnel:

```bash
sudo wg-quick up wg0
```

## 11. VPN Connection Verification

After configuring the clients, I used WireGuard's monitoring commands to inspect VPN connectivity.

### Check WireGuard Status

```bash
sudo wg show
```

The output displays information such as:

- WireGuard interface
- Listening port
- Authorized peers
- Peer endpoints
- Latest handshake
- Data transfer statistics

### Verify VPN Interface

```bash
ip -br addr show wg0
```

### Test VPN Connectivity

From the Ubuntu laptop:

```bash
ping -c 4 10.8.0.1
```

This tests connectivity to the Raspberry Pi through the WireGuard tunnel.

### Test Pi-hole DNS

```bash
dig @10.8.0.1 google.com
```

This tests whether Pi-hole responds to DNS requests sent through the VPN interface.

A successful DNS response confirms that the client can reach the DNS service through WireGuard.

## 12. Troubleshooting

### WireGuard Service Configuration

During configuration, I encountered a systemd message indicating that a service unit could not be enabled because it did not contain an installation configuration.

I learned that WireGuard uses an instance-based systemd service.

The correct service name for my configuration was:

```bash
sudo systemctl enable wg-quick@wg0
```

The `wg0` portion identifies the WireGuard interface configuration.

This helped me better understand how systemd template services work.

### VPN Connection Troubleshooting

I used the following commands to inspect the WireGuard interface and connection status:

```bash
sudo wg show
```

```bash
sudo systemctl status wg-quick@wg0
```

```bash
ip -br addr show wg0
```

These commands helped distinguish between an interface that was running and a VPN peer that had actually established a connection.

## 13. Security Considerations

Several security practices were important during this project.

### Private-Key Protection

Each WireGuard peer uses its own private key.

Private keys should never be published in a GitHub repository.

### Configuration File Permissions

WireGuard configuration files containing private keys should have restrictive permissions.

```bash
sudo chmod 600 /etc/wireguard/wg0.conf
```

### Limited Network Exposure

Only the necessary WireGuard UDP port should be exposed for remote VPN connectivity.

Pi-hole's administration interface should not be directly exposed to the public internet.

### Separate Client Identities

Using separate key pairs allows individual devices to be managed or revoked without replacing every client's credentials.

## 14. Skills Demonstrated

- Linux system administration
- WireGuard VPN configuration
- Public-key authentication
- VPN network addressing
- Secure remote access
- Network troubleshooting
- Systemd service management
- SSH administration
- DNS configuration
- Security documentation

## 15. Lessons Learned

This project helped me better understand how VPN connections work beyond simply installing a VPN application.

I learned how WireGuard uses public and private keys to authenticate devices and establish encrypted communication.

Configuring separate clients also helped me understand how VPN addresses and routing rules determine which devices and networks can communicate through a tunnel.

One of the most valuable lessons was understanding the difference between a running WireGuard interface and an established VPN connection.

I learned that successful VPN connectivity should be verified through handshakes, data transfer statistics, and actual network communication tests.

## 16. Future Improvements

Potential improvements include:

- Implementing additional firewall restrictions for VPN clients.
- Monitoring WireGuard connection availability.
- Testing remote connectivity under different network conditions.
- Documenting VPN performance on Raspberry Pi Zero W hardware.
- Adding more detailed VPN troubleshooting examples.
- Evaluating full-tunnel VPN routing as an alternative to split tunneling.

## 17. Conclusion

Configuring WireGuard expanded my Raspberry Pi homelab beyond DNS filtering into encrypted remote access.

Through this project, I gained experience configuring VPN interfaces, managing cryptographic keys, authorizing multiple clients, and troubleshooting Linux networking services.

Integrating WireGuard with Pi-hole also provided an opportunity to explore how VPN clients can securely access DNS filtering services hosted on a private network.

Overall, this project strengthened my understanding of network security and provided practical experience with technologies commonly used in secure remote administration.