#!/bin/sh

for cert in /media/sf_*/zscaler-root-ca.crt /mnt/*/zscaler-root-ca.crt; do
    [ -f "$cert" ] || continue
    sudo cp "$cert" /etc/pki/ca-trust/source/anchors/zscaler-root-ca.crt
    sudo update-ca-trust extract
    echo "Imported Zscaler root CA from $cert"
    exit 0
done

echo "No zscaler-root-ca.crt found in /media/sf_* or /mnt/*" >&2
exit 1
