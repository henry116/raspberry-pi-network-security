#!/usr/bin/env bash

# ==============================================
# Raspberry Pi Firewall
# Pi-hole + WireGuard + SSH
# ==============================================

set -euo pipefail

LAN_IF="wlan0"
VPN_IF="wg0"

LAN_NET="192.168.1.0/24"
VPN_NET="10.8.0.0/24"

SSH_PORT=22
DNS_PORT=53
WG_PORT=51820

BACKUP_DIR="/root/firewall-backups"
BACKUP_FILE="$BACKUP_DIR/iptables-before-apply.rules"

ROLLBACK_UNIT="pihole-fw-rollback"

MODE="${1:---dry-run}"

# ==============================================
# Check privileges and dependencies
# ==============================================

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "[ERROR] Run with sudo."
        exit 1
    fi
}

check_iptables() {
    if command -v iptables >/dev/null 2>&1; then
        echo "[+] iptables installed."
    else
        echo "[+] Installing iptables..."
        apt-get update
        apt-get install -y iptables
    fi

    command -v iptables-save >/dev/null
    command -v iptables-restore >/dev/null
}

# ==============================================
# Build complete IPv4 ruleset
# ==============================================

build_rules() {

cat <<EOF
*filter

:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Established connections
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Loopback
-A INPUT -i lo -j ACCEPT

# SSH from LAN
-A INPUT -i $LAN_IF -s $LAN_NET -p tcp --dport $SSH_PORT -j ACCEPT

# Pi-hole DNS from LAN
-A INPUT -i $LAN_IF -s $LAN_NET -p udp --dport $DNS_PORT -j ACCEPT
-A INPUT -i $LAN_IF -s $LAN_NET -p tcp --dport $DNS_PORT -j ACCEPT

# Pi-hole DNS from WireGuard
-A INPUT -i $VPN_IF -s $VPN_NET -p udp --dport $DNS_PORT -j ACCEPT
-A INPUT -i $VPN_IF -s $VPN_NET -p tcp --dport $DNS_PORT -j ACCEPT

# Pi-hole dashboard from LAN
-A INPUT -i $LAN_IF -s $LAN_NET -p tcp --dport 80 -j ACCEPT
-A INPUT -i $LAN_IF -s $LAN_NET -p tcp --dport 443 -j ACCEPT

# WireGuard server
-A INPUT -i $LAN_IF -p udp --dport $WG_PORT -j ACCEPT

# DHCP replies
-A INPUT -i $LAN_IF -p udp --sport 67 --dport 68 -j ACCEPT

# ICMP for troubleshooting
-A INPUT -p icmp --icmp-type echo-request -s $LAN_NET -j ACCEPT
-A INPUT -p icmp --icmp-type echo-request -s $VPN_NET -j ACCEPT

# VPN clients to home LAN
-A FORWARD -i $VPN_IF -o $LAN_IF -s $VPN_NET -d $LAN_NET -j ACCEPT

# Return traffic
-A FORWARD -i $LAN_IF -o $VPN_IF -s $LAN_NET -d $VPN_NET -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

COMMIT

*nat

:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# VPN NAT
-A POSTROUTING -s $VPN_NET -d $LAN_NET -o $LAN_IF -j MASQUERADE

COMMIT
EOF
}

# ==============================================
# Backup
# ==============================================

backup_rules() {
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    iptables-save > "$BACKUP_FILE"
    chmod 600 "$BACKUP_FILE"

    echo "[+] Firewall backup created."
}

# ==============================================
# Automatic rollback
# ==============================================

start_rollback() {

    echo "[+] Scheduling rollback in 5 minutes..."

    systemd-run \
        --unit="$ROLLBACK_UNIT" \
        --on-active=5m \
        /usr/sbin/iptables-restore "$BACKUP_FILE"

    systemctl is-active --quiet "$ROLLBACK_UNIT.timer" || {
        echo "[ERROR] Rollback timer not active."
        exit 1
    }

    echo "[+] Rollback timer confirmed."
}

# ==============================================
# Apply firewall
# ==============================================

apply_firewall() {

    check_root
    check_iptables

    if ! command -v systemd-run >/dev/null; then
        echo "[ERROR] systemd-run is required."
        exit 1
    fi

    if systemctl is-active --quiet "$ROLLBACK_UNIT.timer"; then
        echo "[ERROR] Existing rollback timer is active."
        echo "Resolve it before applying another configuration."
        exit 1
    fi

    RULES_FILE=$(mktemp)
    trap 'rm -f "$RULES_FILE"' EXIT

    build_rules > "$RULES_FILE"

    echo "[+] Validating firewall syntax..."
    iptables-restore --test < "$RULES_FILE"

    backup_rules
    start_rollback

    echo "[+] Applying firewall..."
    iptables-restore < "$RULES_FILE"

    echo
    echo "[+] Firewall applied."
    echo "[!] Automatic rollback scheduled in 5 minutes."
    echo "[!] Test SSH, DNS, WireGuard, and LAN access."
    echo
    echo "If everything works, run:"
    echo "sudo ./firewall.sh --confirm"
}

# ==============================================
# Confirm working firewall
# ==============================================

confirm_firewall() {

    check_root

    if systemctl is-active --quiet "$ROLLBACK_UNIT.timer"; then
        systemctl stop "$ROLLBACK_UNIT.timer"
        echo "[+] Rollback canceled."
    else
        echo "[!] No active rollback timer found."
    fi

    echo "[+] Current IPv4 firewall policies:"
    iptables -S | head -n 3

    echo
    echo "[!] Rules are not yet saved for reboot."
}

# ==============================================
# Main
# ==============================================

case "$MODE" in

    --dry-run)
        echo "[+] Previewing proposed firewall:"
        build_rules
        ;;

    --apply)
        apply_firewall
        ;;

    --confirm)
        confirm_firewall
        ;;

    *)
        echo "Usage:"
        echo "  $0 --dry-run"
        echo "  sudo $0 --apply"
        echo "  sudo $0 --confirm"
        exit 1
        ;;
esac
