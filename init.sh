#!/bin/sh

sudo dnf upgrade -y

sudo dnf install -y openssh-server
sudo systemctl enable --now sshd
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

[ -x ~/.local/bin/mise ] || curl -fsSL https://mise.run | sh
mkdir -p ~/.config/mise
[ -f ~/.config/mise/config.toml ] || curl -fsSL https://raw.githubusercontent.com/chubbyhippo/virtualbox-fedora/refs/heads/main/mise.toml -o ~/.config/mise/config.toml

rpm -q jetbrains-mono-nerd-fonts >/dev/null 2>&1 || {
    sudo dnf copr enable -y aquacash5/nerd-fonts
    sudo dnf install -y jetbrains-mono-nerd-fonts
}