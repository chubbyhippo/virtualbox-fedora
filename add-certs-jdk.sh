#!/bin/sh

# mise's JDK (installed via mise.toml, not the system java-*-openjdk) ships its
# own bundled cacerts truststore, independent of the system trust store
# (update-ca-trust, done by add-certs.sh) — same gap as Firefox and npm, see
# the README. This imports the Zscaler root CA into that truststore with
# keytool, so tools like Maven/Gradle can fetch dependencies under
# interception.

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

keytool_bin="$(command -v keytool || true)"
[ -n "$keytool_bin" ] || {
    echo "keytool not found on PATH — install java first (mise install java, or sudo dnf install java-latest-openjdk-devel)" >&2
    exit 1
}

java_home="$(dirname "$(dirname "$(readlink -f "$keytool_bin")")")"
cacerts="$java_home/lib/security/cacerts"
[ -f "$cacerts" ] || {
    echo "no cacerts file found at $cacerts" >&2
    exit 1
}

for cert in /media/sf_*/zscaler-root-ca.crt /mnt/*/zscaler-root-ca.crt; do
    [ -f "$cert" ] || continue
    if keytool -list -keystore "$cacerts" -storepass changeit -alias zscaler-root-ca >/dev/null 2>&1; then
        echo "Zscaler root CA already present in $cacerts"
        exit 0
    fi
    keytool -importcert -noprompt -trustcacerts \
        -alias zscaler-root-ca \
        -file "$cert" \
        -keystore "$cacerts" \
        -storepass changeit
    echo "Imported Zscaler root CA from $cert into $cacerts"
    exit 0
done

echo "No zscaler-root-ca.crt found in /media/sf_* or /mnt/*" >&2
exit 1
