#!/bin/bash
sqlite3 gitea.db "select passwd,salt,name from user" | while IFS='|' read -r passwd salt name; do
    digest=$(echo "$passwd" | xxd -r -p | base64)
    salt_b64=$(echo "$salt" | xxd -r -p | base64)
    echo "${name}:sha256:50000:${salt_b64}:${digest}"
done | tee gitea.hashes   
