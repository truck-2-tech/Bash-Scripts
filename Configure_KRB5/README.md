# krb5-config-generator

A Bash utility for automating Kerberos realm configuration on Linux systems, designed for penetration testing, CTF competitions, and Active Directory assessments.

## Overview

This script simplifies the process of configuring `/etc/krb5.conf` for Kerberos authentication. It automatically backs up existing configurations, prompts for realm details, and generates a properly formatted configuration file compatible with Impacket, NetExec, and other security tools.

## Features

- **Automatic Backup**: Creates timestamped backups of existing `krb5.conf` files before modification
- **Interactive Input**: Prompts for domain FQDN, realm name, and Domain Controller hostname
- **Input Validation**: Ensures all required fields are provided before generating configuration
- **Case Normalization**: Automatically converts realm names to uppercase and domains to lowercase
- **Preview Mode**: Displays generated configuration before writing to disk
- **Safety Confirmation**: Requires explicit user confirmation before overwriting system files

## Requirements

- Linux operating system (Kali, Parrot, Ubuntu, etc.)
- `sudo` privileges
- Bash shell
- Existing `krb5-user` package (optional, script creates config regardless)

## Installation

1. Clone or download the script:
   ```bash
   wget https://github.com/truck-2-tech/Bash-Scripts/new/main/Configure_KRB5/configure_krb5.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x configure_krb5.sh
   ```

## Usage

Execute the script with sudo privileges:

```bash
sudo ./configure_krb5.sh
```

### Interactive Prompts

The script will request the following information:

1. **Domain FQDN**: The fully qualified domain name (e.g., `voleur.htb`)
2. **Realm Name**: The Kerberos realm in uppercase (e.g., `VOLEUR.HTB`)
3. **Domain Controller Hostname**: The FQDN of the KDC (e.g., `dc.voleur.htb`)

### Example Session

```
=== Kerberos Configuration Script ===
[*] Backing up existing /etc/krb5.conf to /etc/krb5.conf.bak.2026-07-10_02-45-30
[+] Backup created successfully.

Please enter the following details for your Kerberos realm:
Domain FQDN (e.g., voleur.htb): voleur.htb
Realm Name (e.g., VOLEUR.HTB, usually uppercase): VOLEUR.HTB
Domain Controller Hostname (e.g., dc.voleur.htb): dc.voleur.htb

[*] Generating configuration for:
    Realm: VOLEUR.HTB
    Domain: voleur.htb
    KDC: dc.voleur.htb

=== Generated Configuration ===
[libdefaults]
    default_realm = VOLEUR.HTB
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    VOLEUR.HTB = {
        kdc = dc.voleur.htb
        admin_server = dc.voleur.htb
        default_domain = voleur.htb
    }

[domain_realm]
    .voleur.htb = VOLEUR.HTB
    voleur.htb = VOLEUR.HTB

[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log
===============================

Do you want to write this to /etc/krb5.conf? (y/n): y
[+] /etc/krb5.conf has been updated successfully.
[!] Remember to add 'dc.voleur.htb' to your /etc/hosts if DNS is not resolving it.
```

## Generated Configuration

The script produces a `krb5.conf` file with the following sections:

### [libdefaults]
- Sets the default realm
- Disables DNS lookups for realms and KDCs (critical for CTF environments)
- Configures ticket lifetime (24 hours) and renewal period (7 days)
- Enables ticket forwarding

### [realms]
- Defines the KDC and admin server locations
- Sets the default domain for the realm

### [domain_realm]
- Maps domain names to Kerberos realms (both with and without leading dot)

### [logging]
- Configures log file locations for Kerberos libraries, KDC, and admin server

## Post-Configuration Steps

1. **Update /etc/hosts**: Ensure the Domain Controller hostname resolves correctly:
   ```bash
   echo "10.129.232.130 dc.voleur.htb" | sudo tee -a /etc/hosts
   ```

2. **Verify Time Synchronization**: Kerberos requires clock skew less than 5 minutes:
   ```bash
   date
   # If incorrect: sudo date -s "YYYY-MM-DD HH:MM:SS"
   ```

3. **Test Authentication**: Obtain a TGT to verify configuration:
   ```bash
   impacket-getTGT voleur.htb/username:password -dc-ip 10.129.232.130
   klist
   ```

4. **Use with NetExec**:
   ```bash
   export KRB5CCNAME=$(pwd)/username.ccache
   nxc smb dc.voleur.htb -u username -k --use-kcache --users
   ```

## Backup and Recovery

Backups are stored in `/etc/` with timestamps:
```
/etc/krb5.conf.bak.2026-07-10_02-45-30
```

To restore a previous configuration:
```bash
sudo cp /etc/krb5.conf.bak.YYYY-MM-DD_HH-MM-SS /etc/krb5.conf
```

## Use Cases

### Penetration Testing
Configure Kerberos for Active Directory assessments without manually editing configuration files.

### CTF Competitions
Quickly switch between different machine realms during HackTheBox or TryHackMe challenges.

### Lab Environments
Set up temporary Kerberos configurations for isolated test networks.

### Multi-Domain Assessments
Maintain backups when switching between different target domains.

## Troubleshooting

### Error: STATUS_NOT_SUPPORTED
Ensure you are using Kerberos authentication (`-k` flag) instead of NTLM. NTLM is often disabled on modern Domain Controllers.

### Error: Clock skew too great
Synchronize your system time with the target domain:
```bash
sudo ntpdate <dc_ip>
# Or manually:
sudo date -s "YYYY-MM-DD HH:MM:SS"
```

### Error: Cannot find KDC
Verify `/etc/hosts` contains the correct DC hostname and IP address. DNS lookups are disabled by default in the generated config.

### kinit fails with "Preauthentication failed"
Verify credentials are correct and the realm name matches exactly (case-sensitive).

## Security Considerations

- **Backup Integrity**: Always verify backup files before overwriting configurations
- **Credential Handling**: Never store passwords in the configuration file
- **Ticket Cache**: Use `KRB5CCNAME` environment variable to manage ticket locations
- **Cleanup**: Remove cached tickets with `kdestroy` after assessments

## Contributing

Contributions are welcome. Please ensure:
- Backward compatibility with existing `krb5.conf` formats
- Proper error handling for edge cases
- Clear documentation of new features

## License

This project is provided as-is for educational and authorized penetration testing purposes only.

## Disclaimer

This tool is intended for legitimate security assessments, penetration testing engagements, and educational purposes. Always obtain proper authorization before testing systems you do not own.

