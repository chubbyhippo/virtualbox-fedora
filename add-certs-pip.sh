#!/bin/sh

# pip ignores the system trust store by default (it bundles its own certifi
# CA file), unlike curl/dnf/go — same gap as Firefox and npm, see the README.
# This points pip's own config at the system CA bundle add-certs.sh already
# updated via update-ca-trust, so later pip installs (e.g. init-el-extras.sh's
# debugpy) trust the Zscaler root CA with no PIP_CERT env var needed.

pip_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pip"
pip_conf="$pip_conf_dir/pip.conf"
system_bundle="/etc/pki/tls/certs/ca-bundle.crt"

for cert in /media/sf_*/zscaler-root-ca.crt /mnt/*/zscaler-root-ca.crt; do
    [ -f "$cert" ] || continue
    [ -f "$system_bundle" ] || {
        echo "no system CA bundle at $system_bundle — run add-certs.sh first" >&2
        exit 1
    }
    mkdir -p "$pip_conf_dir"
    if [ -f "$pip_conf" ] && grep -q '^cert' "$pip_conf"; then
        sed -i "s|^cert.*|cert = $system_bundle|" "$pip_conf"
    elif [ -f "$pip_conf" ] && grep -q '^\[global\]' "$pip_conf"; then
        sed -i "/^\[global\]/a cert = $system_bundle" "$pip_conf"
    else
        printf '[global]\ncert = %s\n' "$system_bundle" >> "$pip_conf"
    fi
    echo "Pointed pip at $system_bundle (trusts the Zscaler root CA from $cert)"
    exit 0
done

echo "No zscaler-root-ca.crt found in /media/sf_* or /mnt/*" >&2
exit 1
