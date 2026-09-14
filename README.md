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
