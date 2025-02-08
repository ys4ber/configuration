#!/bin/bash
echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Installing basic tools..."
sudo apt-get install -y vim git zsh curl wget gpg apt-transport-https

echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y
rm google-chrome-stable_current_amd64.deb

echo "Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

echo "Installing Snap packages..."
sudo apt-get install -y snapd
sudo snap install discord
sudo snap install spotify
sudo snap install brave

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Generating SSH key..."
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo "Your SSH public key is:"
cat ~/.ssh/id_ed25519.pub

echo "Setting ZSH as default shell..."
chsh -s $(which zsh)

echo "Changing Oh My Zsh theme to bira..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' ~/.zshrc

echo "Setup complete! Please log out and log back in for all changes to take effect."
