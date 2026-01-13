#!/bin/bash
# Simple setup script for Terraform + GCP
# Automatically installs gcloud and Terraform if not present

set -e

echo "=== GCP + Terraform Setup Script ==="
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="unknown"
fi

# Function to install gcloud CLI
install_gcloud() {
    echo "📦 Installing gcloud CLI..."
    
    if [[ "$OS" == "linux" ]]; then
        # Check for package manager
        if command -v apt-get &> /dev/null; then
            echo "Using apt-get to install gcloud..."
            # Add gcloud repo
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            sudo apt-get update && sudo apt-get install -y google-cloud-sdk
        elif command -v yum &> /dev/null; then
            echo "Using yum to install gcloud..."
            sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
            sudo yum install -y google-cloud-sdk
        elif command -v brew &> /dev/null; then
            echo "Using Homebrew to install gcloud..."
            brew install --cask google-cloud-sdk
        else
            echo "⚠️  Please install gcloud manually: https://cloud.google.com/sdk/docs/install"
            return 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            echo "Using Homebrew to install gcloud..."
            brew install --cask google-cloud-sdk
        else
            echo "⚠️  Please install Homebrew first: https://brew.sh"
            echo "   Or install gcloud manually: https://cloud.google.com/sdk/docs/install"
            return 1
        fi
    else
        echo "⚠️  Please install gcloud manually: https://cloud.google.com/sdk/docs/install"
        return 1
    fi
    
    echo "✅ gcloud installed"
    return 0
}

# Function to install Terraform
install_terraform() {
    echo "📦 Installing Terraform..."
    
    if [[ "$OS" == "linux" ]]; then
        if command -v apt-get &> /dev/null; then
            echo "Using apt-get to install Terraform..."
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            sudo apt-get update && sudo apt-get install -y terraform
        elif command -v yum &> /dev/null; then
            echo "Using yum to install Terraform..."
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo yum install -y terraform
        elif command -v brew &> /dev/null; then
            echo "Using Homebrew to install Terraform..."
            brew install terraform
        else
            echo "⚠️  Please install Terraform manually: https://developer.hashicorp.com/terraform/downloads"
            return 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            echo "Using Homebrew to install Terraform..."
            brew install terraform
        else
            echo "⚠️  Please install Homebrew first: https://brew.sh"
            echo "   Or install Terraform manually: https://developer.hashicorp.com/terraform/downloads"
            return 1
        fi
    else
        echo "⚠️  Please install Terraform manually: https://developer.hashicorp.com/terraform/downloads"
        return 1
    fi
    
    echo "✅ Terraform installed"
    return 0
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found!"
    if ! install_gcloud; then
        echo ""
        echo "Please install gcloud manually and run this script again."
        exit 1
    fi
    
    # Verify installation
    sleep 2
    if ! command -v gcloud &> /dev/null; then
        echo "⚠️  gcloud installed but not in PATH. Please restart your terminal and run this script again."
        exit 1
    fi
fi

echo "✅ gcloud CLI found"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found!"
    if ! install_terraform; then
        echo ""
        echo "Please install Terraform manually and run this script again."
        exit 1
    fi
    
    # Verify installation
    sleep 2
    if ! command -v terraform &> /dev/null; then
        echo "⚠️  Terraform installed but not in PATH. Please restart your terminal and run this script again."
        exit 1
    fi
fi

echo "✅ Terraform found"
echo ""

# Authenticate with GCP
echo "=== Step 1: Authenticate with GCP ==="
echo "This will open your browser to login..."
gcloud auth login

echo ""
echo "=== Step 2: Set up Application Default Credentials ==="
echo "This allows Terraform to authenticate automatically..."
gcloud auth application-default login

echo ""
echo "=== Step 3: Set your GCP project ==="
read -p "Enter your GCP Project ID: " PROJECT_ID
gcloud config set project "$PROJECT_ID"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Your project is set to: $PROJECT_ID"
echo "You can now run: ./scripts/deploy.sh $PROJECT_ID"
