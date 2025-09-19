#!/bin/bash

# Debian Security Hardening Script
# Interactive setup for securing a fresh Debian installation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

get_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    read -p "$prompt [$default]: " result
    echo "${result:-$default}"
}

if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons."
   exit 1
fi

print_status "=== Debian Security Hardening Script ==="
print_status "This script will help you secure your Debian installation."
echo ""

# 1. System Updates
print_question "Step 1: Update system packages"
if ask_yes_no "Do you want to update all system packages?"; then
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_status "System updated successfully!"
else
    print_warning "Skipping system updates. This is not recommended!"
fi

echo ""

# 2. Create non-root user
print_question "Step 2: User management"
if ask_yes_no "Do you want to create a new non-root user?"; then
    username=$(get_input "Enter username for new user" "secureuser")
    sudo adduser "$username"
    sudo usermod -aG sudo "$username"
    print_status "User $username created and added to sudo group!"
fi

echo ""

# 3. SSH Configuration
print_question "Step 3: SSH Server hardening"
if ask_yes_no "Do you want to harden SSH configuration?"; then
    
    # Backup original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    if ask_yes_no "Change SSH port from default 22?"; then
        ssh_port=$(get_input "Enter new SSH port" "2222")
        sudo sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
        print_status "SSH port changed to $ssh_port"
    else
        ssh_port="22"
    fi
    
    if ask_yes_no "Disable root login via SSH?"; then
        sudo sed -i "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
        sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
        print_status "Root login disabled"
    fi
    
    if ask_yes_no "Disable password authentication (use keys only)?"; then
        print_warning "Make sure you have SSH keys set up before enabling this!"
        if ask_yes_no "Are you sure you want to disable password auth?"; then
            sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
            sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
            print_status "Password authentication disabled"
        fi
    fi
    
    # Additional SSH hardening
    echo "
# Additional security settings
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2" | sudo tee -a /etc/ssh/sshd_config
    
    sudo systemctl restart ssh
    print_status "SSH configuration updated and service restarted!"
else
    ssh_port="22"
fi

echo ""

# 4. Firewall setup
print_question "Step 4: Firewall configuration"
if ask_yes_no "Do you want to set up UFW firewall?"; then
    sudo apt install ufw -y
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # SSH access
    sudo ufw allow $ssh_port/tcp
    print_status "Allowed SSH on port $ssh_port"
    
    # Web server ports
    if ask_yes_no "Allow HTTP/HTTPS traffic (ports 80/443)?"; then
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        print_status "Allowed HTTP/HTTPS traffic"
    fi
    
    # Custom ports
    if ask_yes_no "Do you want to open any additional ports?"; then
        while true; do
            port=$(get_input "Enter port number (or 'done' to finish)" "done")
            if [[ "$port" == "done" ]]; then
                break
            fi
            protocol=$(get_input "Protocol (tcp/udp)" "tcp")
            sudo ufw allow $port/$protocol
            print_status "Allowed port $port/$protocol"
        done
    fi
    
    sudo ufw enable
    print_status "Firewall enabled!"
fi

echo ""

# 5. Automatic updates
print_question "Step 5: Automatic security updates"
if ask_yes_no "Do you want to enable automatic security updates?"; then
    sudo apt install unattended-upgrades -y
    sudo dpkg-reconfigure -plow unattended-upgrades
    print_status "Automatic updates configured!"
fi

echo ""

# 6. Fail2Ban
print_question "Step 6: Intrusion prevention with Fail2Ban"
if ask_yes_no "Do you want to install and configure Fail2Ban?"; then
    sudo apt install fail2ban -y
    
    # Create local configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = $ssh_port
EOF
    
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    print_status "Fail2Ban installed and configured!"
fi

echo ""

# 7. Security tools
print_question "Step 7: Security monitoring tools"
if ask_yes_no "Do you want to install security monitoring tools (rkhunter, chkrootkit)?"; then
    sudo apt install rkhunter chkrootkit -y
    
    sudo rkhunter --update
    sudo rkhunter --propupd
    
    print_status "Security tools installed!"
    print_status "Run 'sudo rkhunter -c' to check for rootkits"
    print_status "Run 'sudo chkrootkit' to check for rootkits"
fi

echo ""

# 8. Log monitoring
print_question "Step 8: Log monitoring"
if ask_yes_no "Do you want to install logwatch for log monitoring?"; then
    sudo apt install logwatch -y
    print_status "Logwatch installed!"
    print_status "Run 'sudo logwatch' to view system logs summary"
fi

echo ""

# 9. Web server hardening
print_question "Step 9: Web server hardening"
web_server=""
if command -v apache2 >/dev/null 2>&1; then
    web_server="apache2"
    print_status "Apache2 detected"
elif command -v nginx >/dev/null 2>&1; then
    web_server="nginx"
    print_status "Nginx detected"
fi

if [[ -n "$web_server" ]]; then
    if ask_yes_no "Do you want to apply basic $web_server hardening?"; then
        if [[ "$web_server" == "apache2" ]]; then
            # Apache hardening
            sudo a2enmod headers
            echo "
# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection \"1; mode=block\"
Header always set Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\"
Header always set Content-Security-Policy \"default-src 'self'\"

# Hide Apache version
ServerTokens Prod
ServerSignature Off" | sudo tee /etc/apache2/conf-available/security-headers.conf
            
            sudo a2enconf security-headers
            sudo systemctl restart apache2
            
        elif [[ "$web_server" == "nginx" ]]; then
            # Nginx hardening
            echo "
# Security headers
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header X-XSS-Protection \"1; mode=block\";
add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\";

# Hide Nginx version
server_tokens off;" | sudo tee /etc/nginx/conf.d/security-headers.conf
            
            sudo systemctl restart nginx
        fi
        
        print_status "$web_server hardened with security headers!"
    fi
fi

echo ""

# 10. System hardening
print_question "Step 10: Additional system hardening"
if ask_yes_no "Do you want to apply additional system hardening?"; then
    
    # Disable unused network protocols
    echo "
# Disable unused network protocols
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true" | sudo tee /etc/modprobe.d/blacklist-rare-network.conf
    
    # Kernel parameters
    echo "
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 1" | sudo tee /etc/sysctl.d/99-security.conf
    
    sudo sysctl -p /etc/sysctl.d/99-security.conf
    
    print_status "Additional system hardening applied!"
fi

echo ""

# Final summary
print_status "=== Security Hardening Complete ==="
print_status "Your Debian system has been hardened with the following:"

echo "✓ System packages updated"
echo "✓ SSH server configured (port: $ssh_port)"
echo "✓ Firewall configured and enabled"
echo "✓ Automatic security updates enabled"
echo "✓ Fail2Ban installed for intrusion prevention"
echo "✓ Security monitoring tools installed"
echo "✓ System hardening parameters applied"

print_warning "Important reminders:"
echo "1. Test SSH access before closing this session!"
echo "2. Make sure you can access your system on port $ssh_port"
echo "3. Consider setting up SSH key authentication"
echo "4. Regularly monitor logs and run security scans"
echo "5. Keep your system updated with 'sudo apt update && sudo apt upgrade'"

print_status "Script completed successfully!"
