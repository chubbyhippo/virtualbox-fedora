# virtualbox-fedora
```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/init.sh | sh
```

If the above `curl` fails with an SSL/certificate error, your host likely runs Zscaler — see [Zscaler SSL on the host](#zscaler-ssl-on-the-host-optional) below before retrying.

`init.sh` also runs [`init-el-extras.sh`](init-el-extras.sh), which installs the language servers and debuggers (clangd, gdb, lldb-dap, pylsp, debugpy, clojure-lsp, Guile/Chez, ElixirLS, erlang_ls, gopls, delve, jdtls, rust-analyzer, typescript-language-server, vscode-js-debug, GnuCOBOL) used by the optional per-language `extras/*.el` layers of a companion Emacs config — see the comments at the top of that script for the runtimes it expects from `mise.toml` and what it deliberately leaves out (Haskell, SuperBOL).


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

   Shared folders are only accessible to users in the `vboxsf` group. `init.sh` adds the current user to it automatically (a log out/reboot is needed afterwards to pick it up), but on a fresh VM before running `init.sh` you may need to do it manually first:
   ```sh
   sudo usermod -aG vboxsf $USER
   ```
   then log out and back in (or reboot) before accessing `/media/sf_*`.

3. In the VM, run `add-certs.sh` directly from the shared folder — no `curl` involved:
   ```sh
   sh /media/sf_<share-name>/add-certs.sh
   ```
   This copies the cert into `/etc/pki/ca-trust/source/anchors/` and runs `update-ca-trust extract`.

4. `curl` (and `init.sh`) now works normally. Continue with:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/init.sh | sh
   ```

### Importing the root CA into the browser (Firefox)

`update-ca-trust` (step 3 above) makes the system trust store — and anything that relies on it, like `curl`, `dnf`, and Chrome/Chromium via `p11-kit` — trust the Zscaler root CA. **Firefox does not use the system trust store on Linux** and keeps its own certificate database, so HTTPS sites will still show a security warning in Firefox until the cert is imported there separately:

1. Open Firefox and go to `about:preferences#privacy`, then scroll down to **Certificates** and click **View Certificates…**.
2. In the **Certificate Manager**, go to the **Authorities** tab and click **Import…**.
3. Select `zscaler-root-ca.crt` (from the shared folder, e.g. `/media/sf_<share-name>/zscaler-root-ca.crt`, or wherever you copied it).
4. Check **Trust this CA to identify websites** and confirm.
5. Reload any open tabs — Firefox should now trust intercepted HTTPS connections.

Chrome/Chromium-based browsers on Fedora normally pick up the system trust store automatically after `update-ca-trust extract`, so no separate import is needed there; if a Chromium-based browser still complains, import the same `.crt` file via its own `chrome://settings/certificates` (or `chrome://certificate-manager`) page the same way.

### Importing the root CA for npm

npm (and Node in general) has the same gap as Firefox — it doesn't consult the system trust store either, so `npm install` (used by [`init-el-extras.sh`](init-el-extras.sh) for the TypeScript/HTML language servers) fails under Zscaler interception even after `add-certs.sh` runs. From the shared folder, without curl:

```sh
sh /media/sf_<share-name>/add-certs-npm.sh
```

This copies the cert to `~/.config/npm/zscaler-root-ca.crt` and runs `npm config set cafile` to point at it, scoped to your npm user config — no reboot or new session needed.

### If `curl` can't reach GitHub at all (no shared folder yet)

On a brand new VM you may not have a shared folder or Guest Additions set up yet, so you can't get `zscaler-root-ca.crt` or `add-certs.sh` onto the VM through `/media/sf_*`. In that case, download this repo directly onto the **host** and copy the whole checkout into the VM instead of relying on `curl`/GitHub raw links from inside the guest:

1. On the host, clone or download this repo as a zip (browsers use the OS trust store, so Zscaler's cert works fine there).
2. Copy the folder into the VM via a temporary shared folder, `scp`, or by attaching it as an ISO/drag-and-drop (if Guest Additions are already installed).
3. Run the scripts locally from that copy:
   ```sh
   sh add-certs.sh   # imports the Zscaler root CA
   sh init.sh        # curl now works; runs the rest of the setup
   ```
