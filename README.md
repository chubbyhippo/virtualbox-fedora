# virtualbox-fedora
```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/init.sh | sh
```

## Connecting to the SSH server

### Option 1: VirtualBox NAT port forwarding

If the VM network adapter is set to **NAT**, forward a host port to the guest's port 22:

1. VM **Settings** > **Network** > **Adapter 1** > **Advanced** > **Port Forwarding**
2. Add a rule: Protocol `TCP`, Host Port `2222`, Guest Port `22` (leave IPs blank)
3. Connect from the host:
   ```sh
   ssh -p 2222 <user>@127.0.0.1
   ```

### Option 2: Bridged / Host-only adapter

If the VM network adapter is set to **Bridged** or **Host-only**, find the guest's IP address on the VM:

```sh
ip -4 addr show scope global
```

Then connect from the host using that IP:

```sh
ssh <user>@<vm-ip>
```

## Zscaler SSL on the host (optional)

Skip this section entirely if the host doesn't run Zscaler Client Connector — `init.sh` doesn't touch certs and works as-is.

If the host does run Zscaler, TLS traffic from the VM may be intercepted and fail certificate validation — including `curl` itself, so `init.sh` can't even be downloaded that way until the cert is trusted. Import the Zscaler root CA into the VM **before running `init.sh`, without using curl**, via a shared folder.

1. On the **host** (Windows, PowerShell), export the Zscaler root CA from the Windows certificate store:
   ```powershell
   .\export-zscaler-cert.ps1
   ```
   This creates `zscaler-root-ca.crt` in the current directory.

2. Set up a **VirtualBox shared folder** pointing at a directory containing both `zscaler-root-ca.crt` and `add-certs.sh` (e.g. this repo's checkout), and mount it in the VM (VM **Settings** > **Shared Folders**; enable **Auto-mount** if available).

3. In the VM, run `add-certs.sh` directly from the shared folder — no `curl` involved:
   ```sh
   sh /media/sf_<share-name>/add-certs.sh
   ```
   This copies the cert into `/etc/pki/ca-trust/source/anchors/` and runs `update-ca-trust extract`.

4. `curl` (and `init.sh`) now works normally.
