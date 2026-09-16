#!/bin/sh

zscaler_cert() {
    for cert in /media/sf_*/zscaler-root-ca.crt /mnt/*/zscaler-root-ca.crt; do
        [ -f "$cert" ] && { printf '%s' "$cert"; return 0; }
    done
    return 1
}

if zscaler_cert >/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/add-certs.sh | sh
fi

sudo dnf upgrade -y

sudo dnf install -y @development-tools

sudo dnf install -y openssh-server
sudo systemctl enable --now sshd
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

[ -x ~/.local/bin/mise ] || curl -fsSL https://mise.run | sh
mkdir -p ~/.config/mise
[ -f ~/.config/mise/config.toml ] || curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/mise.toml -o ~/.config/mise/config.toml
~/.local/bin/mise install --yes

if zscaler_cert >/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/add-certs-jdk.sh | sh
    curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/add-certs-npm.sh | sh
fi

sudo dnf install -y emacs

# init.el extras (language servers + debuggers)
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/init-el-extras.sh | /usr/bin/env sh

rpm -q jet-brains-mono-nerd-fonts >/dev/null 2>&1 || {
    sudo dnf copr enable -y aquacash5/nerd-fonts
    sudo dnf install -y jet-brains-mono-nerd-fonts
}

if getent group vboxsf >/dev/null && ! id -nG "$USER" | grep -qw vboxsf; then
    sudo usermod -aG vboxsf "$USER"
    echo "Added $USER to vboxsf group. Log out and back in (or reboot) to access shared folders."
fi