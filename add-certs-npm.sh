#!/bin/sh

# npm/Node don't consult the system trust store (update-ca-trust, done by
# add-certs.sh) — same gap as Firefox, see the README. This makes npm trust
# the Zscaler root CA specifically, so `npm install` works under interception.

for cert in /media/sf_*/zscaler-root-ca.crt /mnt/*/zscaler-root-ca.crt; do
    [ -f "$cert" ] || continue
    mkdir -p "$HOME/.config/npm"
    cp "$cert" "$HOME/.config/npm/zscaler-root-ca.crt"
    npm config set cafile "$HOME/.config/npm/zscaler-root-ca.crt"
    echo "Imported Zscaler root CA from $cert into npm's cafile"
    exit 0
done

echo "No zscaler-root-ca.crt found in /media/sf_* or /mnt/*" >&2
exit 1
