#!/bin/bash

LOG_FILE="drosera-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

set -e

echo "============================="
echo "🚀 Drosera Network Installer"
echo "============================="

function error_exit {
    echo "❌ Error on line $1"
    exit 1
}
trap 'error_exit $LINENO' ERR

# Update & Install Dependencies
echo "📦 Updating & Installing Dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev

# Docker Setup
echo "🐳 Setting up Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Test Docker
echo "🔧 Testing Docker..."
sudo docker run hello-world || echo "⚠️ Docker test failed, check manually."

# Install Drosera CLI
echo "📥 Installing Drosera CLI..."
curl -L https://app.drosera.io/install | bash
source ~/.bashrc
droseraup

# Install Foundry CLI
echo "📥 Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

# Install Bun
echo "📥 Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Initialize Drosera Trap Project
echo "📂 Creating Drosera Trap Project..."
mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap

# Set Git Identity
read -p "✉️  Enter your GitHub Email: " GIT_EMAIL
read -p "👤 Enter your GitHub Username: " GIT_NAME
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

echo "🔧 Initializing Trap..."
forge init -t drosera-network/trap-foundry-template

# Compile and Install Trap Dependencies
bun install
forge build || echo "⚠️ Build completed with warnings."

# Deploy Trap
read -p "🔐 Enter your EVM Private Key (for Trap deployment): " PRIVATE_KEY
export DROSERA_PRIVATE_KEY=$PRIVATE_KEY

echo "🚀 Deploying Trap..."
drosera apply || echo "⚠️ Deployment may need manual input. Type 'ofc' when prompted."

# Operator Setup
echo "📥 Installing Drosera Operator CLI..."
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin

echo "✅ Drosera Operator Installed!"
drosera-operator --version

# Register Operator
read -p "🌐 Enter your VPS Public IP: " VPS_IP
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY

# Create systemd service
echo "🛠️ Creating systemd service..."
sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=Drosera Operator Node
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=/usr/bin/drosera-operator node --db-file-path $HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \
  --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
  --eth-backup-rpc-url https://1rpc.io/holesky \
  --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
  --eth-private-key $PRIVATE_KEY \
  --listen-address 0.0.0.0 \
  --network-external-p2p-address $VPS_IP \
  --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF

# Enable & Start service
echo "📡 Starting Drosera Node..."
sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

# Firewall Settings
echo "🧱 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw --force enable

# Final Checks
echo "✅ Installation completed!"
echo "🔍 Check logs: journalctl -u drosera.service -f"
