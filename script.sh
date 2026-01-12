#!/bin/bash
echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Installing basic tools..."
sudo apt-get install -y vim git zsh curl wget gpg apt-transport-https docker.io \
  docker-compose-v2 gnome-screensaver net-tools podman
if [ -x "$(command -v docker)" ]; then
  sudo usermod -aG docker $USER
fi

echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y
rm google-chrome-stable_current_amd64.deb

echo "Installing VS Code..."
wget -O vscode.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
sudo dpkg -i vscode.deb
rm vscode.deb

echo "Installing Snap packages..."

if ! [ -x "$(command -v snap)" ]; then
  echo "Installing snapd..."
  sudo apt-get install -y snapd
fi

sudo snap install discord
sudo snap install spotify
sudo snap install brave
sudo snap install --classic waveterm

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

echo "Setting dark theme..."
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

echo "Showing seconds on the clock..."
gsettings set org.gnome.desktop.interface clock-show-seconds true

echo "Changing display resolution to 1920x1080..."
xrandr --output $(xrandr | grep ' connected' | cut -f1 -d ' ') --mode 1920x1080

echo "Configuring terminal settings..."
gsettings set org.gnome.Terminal.Legacy.Settings default-size-columns 64
gsettings set org.gnome.Terminal.Legacy.Settings default-size-rows 16
gsettings set org.gnome.desktop.interface monospace-font-name 'Custom 9'

echo "Setting lock screen shortcut to Ctrl + Alt + L..."
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver '<Control><Alt>l'

echo "Creating slock command..." # this is locking the screen and mute the machine "
echo "alias slock='gnome-screensaver-command -l && pactl set-sink-volume @DEFAULT_SINK@ 0%'" >> ~/.zshrc && source ~/.zshrc

echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs npm

echo "Setup complete! Please log out and log back in for all changes to take effect."
