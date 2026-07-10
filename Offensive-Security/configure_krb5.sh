#!/bin/bash

# Define the default path for krb5.conf
KRB5_PATH="/etc/krb5.conf"
BACKUP_PATH="${KRB5_PATH}.bak.$(date +%F_%H-%M-%S)"

echo "=== Kerberos Configuration Script ==="

# 1. Backup existing configuration
if [ -f "$KRB5_PATH" ]; then
    echo "[*] Backing up existing $KRB5_PATH to $BACKUP_PATH"
    sudo cp "$KRB5_PATH" "$BACKUP_PATH"
    echo "[+] Backup created successfully."
else
    echo "[!] No existing $KRB5_PATH found. Skipping backup."
fi

# 2. Gather User Input
echo ""
echo "Please enter the following details for your Kerberos realm:"
read -p "Domain FQDN (e.g., voleur.htb): " DOMAIN_FQDN
read -p "Realm Name (e.g., VOLEUR.HTB, usually uppercase): " REALM
read -p "Domain Controller Hostname (e.g., dc.voleur.htb): " DC_HOST

# Validate input (basic check)
if [ -z "$DOMAIN_FQDN" ] || [ -z "$REALM" ] || [ -z "$DC_HOST" ]; then
    echo "[!] Error: All fields are required. Exiting."
    exit 1
fi

# Normalize inputs
REALM_UPPER=$(echo "$REALM" | tr '[:lower:]' '[:upper:]')
DOMAIN_LOWER=$(echo "$DOMAIN_FQDN" | tr '[:upper:]' '[:lower:]')

echo ""
echo "[*] Generating configuration for:"
echo "    Realm: $REALM_UPPER"
echo "    Domain: $DOMAIN_LOWER"
echo "    KDC: $DC_HOST"

# 3. Generate the new krb5.conf content
# Using a heredoc to preserve formatting
NEW_CONFIG=$(cat <<EOF
[libdefaults]
    default_realm = $REALM_UPPER
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    $REALM_UPPER = {
        kdc = $DC_HOST
        admin_server = $DC_HOST
        default_domain = $DOMAIN_LOWER
    }

[domain_realm]
    .$DOMAIN_LOWER = $REALM_UPPER
    $DOMAIN_LOWER = $REALM_UPPER

[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log
EOF
)

# 4. Display and Confirm
echo ""
echo "=== Generated Configuration ==="
echo "$NEW_CONFIG"
echo "==============================="
echo ""

read -p "Do you want to write this to $KRB5_PATH? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "$NEW_CONFIG" | sudo tee "$KRB5_PATH" > /dev/null
    echo "[+] $KRB5_PATH has been updated successfully."
    echo "[!] Remember to add '$DC_HOST' to your /etc/hosts if DNS is not resolving it."
else
    echo "[!] Configuration aborted. No changes made."
fi   
