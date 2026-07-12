# Gitea Hash Extractor (Bash)

A lightweight Bash script to extract and convert Gitea user password hashes from SQLite into hashcat-ready format (Mode 10900: PBKDF2-HMAC-SHA256).

## Overview

Gitea stores passwords as hex-encoded `passwd` and `salt` fields in its SQLite database. Hashcat requires these values to be base64-encoded and formatted as:
```
username:sha256:50000:<base64_salt>:<base64_hash>
```
This script automates the conversion process directly from the database dump.

## Requirements

- `sqlite3` – To query the Gitea database.
- `xxd` – To convert hex strings to binary.
- `base64` – To encode binary data to base64.
- `bash` – Standard shell environment.

## Usage

### 1. Save the Script
Save the following code as `gitea_convert.sh`:

```bash
#!/bin/bash
# gitea_convert.sh - Convert Gitea SQLite hashes to hashcat format

if [ ! -f "gitea.db" ]; then
    echo "Error: gitea.db not found in current directory."
    exit 1
fi

sqlite3 gitea.db "select passwd,salt,name from user" | while IFS='|' read -r passwd salt name; do
    # Convert hex to binary, then to base64
    # The -w 0 flag prevents line wrapping (critical for hashcat)
    digest=$(echo "$passwd" | xxd -r -p | base64 -w 0)
    salt_b64=$(echo "$salt" | xxd -r -p | base64 -w 0)
    
    # Output in hashcat mode 10900 format
    echo "${name}:sha256:50000:${salt_b64}:${digest}"
done | tee gitea.hashes

echo "Conversion complete. Output saved to gitea.hashes"
```

### 2. Make Executable
```bash
chmod +x gitea_convert.sh
```

### 3. Run the Script
Ensure `gitea.db` is in the same directory, then execute:
```bash
./gitea_convert.sh
```

## Output Format

The script generates a file named `gitea.hashes` with lines formatted for hashcat:
```
administrator:sha256:50000:pFxD023OMHYVixnCxpbvew==:G/CpVhzwdsX8DXbhQHiKkbUoFgnDhHkYOf1umZbTu/XJG47ua9UIHkIIXtC+d5wu+G0=
richard:sha256:50000:188slid90W2V7Vwzu1JLYg==:S0tTdm/pRufikbEG/Nb0lik0EW7JrHipmzv2sGz4Voqu3SZ+wCs5rrJE2D+4uJwkO14=
```

## Cracking with Hashcat

Use hashcat mode 10900 with the `--username` flag to preserve usernames in reports:

```bash
hashcat -m 10900 --username gitea.hashes /path/to/wordlist.txt
```

- `-m 10900`: Specifies PBKDF2-HMAC-SHA256.
- `--username`: Tells hashcat the format includes `user:hash`.
- `50000`: The iteration count is embedded in the hash string.

## Technical Details

- **Hex to Binary**: `xxd -r -p` reverses the plain hex dump into raw binary.
- **Binary to Base64**: `base64 -w 0` encodes the binary without line wrapping. This flag is specific to GNU coreutils; macOS users may need to use `base64` without flags (as BSD base64 does not wrap by default) or pipe through `tr -d '\n'`.
- **Iterations**: Gitea default is 50,000 (defined in `pbkdf2$50000$50` algorithm string). Newer versions may use 320,000 iterations (`pbkdf2_v2`). Adjust the script if your configuration differs.



