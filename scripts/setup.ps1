# Simple setup script for Terraform + GCP (PowerShell)
# Automatically installs gcloud and Terraform if not present

Write-Host "=== GCP + Terraform Setup Script ===" -ForegroundColor Cyan
Write-Host ""

# Function to install gcloud CLI
function Install-GCloud {
    Write-Host "📦 Installing gcloud CLI..." -ForegroundColor Yellow
    
    # Try winget first (Windows 10/11)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Using winget to install gcloud..." -ForegroundColor Gray
        winget install --id Google.CloudSDK -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ gcloud installed via winget" -ForegroundColor Green
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            return $true
        }
    }
    
    # Try chocolatey if available
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Using Chocolatey to install gcloud..." -ForegroundColor Gray
        choco install gcloudsdk -y
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ gcloud installed via Chocolatey" -ForegroundColor Green
            refreshenv
            return $true
        }
    }
    
    # Manual installation instructions
    Write-Host "⚠️  Automatic installation failed. Please install manually:" -ForegroundColor Yellow
    Write-Host "   1. Download from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    Write-Host "   2. Or use: winget install Google.CloudSDK" -ForegroundColor Yellow
    Write-Host "   3. Or use: choco install gcloudsdk" -ForegroundColor Yellow
    return $false
}

# Function to install Terraform
function Install-Terraform {
    Write-Host "📦 Installing Terraform..." -ForegroundColor Yellow
    
    # Try winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Using winget to install Terraform..." -ForegroundColor Gray
        winget install --id HashiCorp.Terraform -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Terraform installed via winget" -ForegroundColor Green
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            return $true
        }
    }
    
    # Try chocolatey if available
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Using Chocolatey to install Terraform..." -ForegroundColor Gray
        choco install terraform -y
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Terraform installed via Chocolatey" -ForegroundColor Green
            refreshenv
            return $true
        }
    }
    
    # Manual installation instructions
    Write-Host "⚠️  Automatic installation failed. Please install manually:" -ForegroundColor Yellow
    Write-Host "   1. Download from: https://developer.hashicorp.com/terraform/downloads" -ForegroundColor Yellow
    Write-Host "   2. Or use: winget install HashiCorp.Terraform" -ForegroundColor Yellow
    Write-Host "   3. Or use: choco install terraform" -ForegroundColor Yellow
    return $false
}

# Check and install gcloud
try {
    $null = Get-Command gcloud -ErrorAction Stop
    Write-Host "✅ gcloud CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ gcloud CLI not found!" -ForegroundColor Red
    if (-not (Install-GCloud)) {
        Write-Host ""
        Write-Host "Please install gcloud manually and run this script again." -ForegroundColor Red
        exit 1
    }
    
    # Verify installation
    Start-Sleep -Seconds 2
    try {
        $null = Get-Command gcloud -ErrorAction Stop
        Write-Host "✅ gcloud CLI verified" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  gcloud installed but not in PATH. Please restart your terminal and run this script again." -ForegroundColor Yellow
        exit 1
    }
}

# Check and install Terraform
try {
    $null = Get-Command terraform -ErrorAction Stop
    Write-Host "✅ Terraform found" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found!" -ForegroundColor Red
    if (-not (Install-Terraform)) {
        Write-Host ""
        Write-Host "Please install Terraform manually and run this script again." -ForegroundColor Red
        exit 1
    }
    
    # Verify installation
    Start-Sleep -Seconds 2
    try {
        $null = Get-Command terraform -ErrorAction Stop
        Write-Host "✅ Terraform verified" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Terraform installed but not in PATH. Please restart your terminal and run this script again." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

# Authenticate with GCP
Write-Host "=== Step 1: Authenticate with GCP ===" -ForegroundColor Cyan
Write-Host "This will open your browser to login..." -ForegroundColor Yellow
gcloud auth login

Write-Host ""
Write-Host "=== Step 2: Set up Application Default Credentials ===" -ForegroundColor Cyan
Write-Host "This allows Terraform to authenticate automatically..." -ForegroundColor Yellow
gcloud auth application-default login

Write-Host ""
Write-Host "=== Step 3: Set your GCP project ===" -ForegroundColor Cyan
$PROJECT_ID = Read-Host "Enter your GCP Project ID"
gcloud config set project $PROJECT_ID

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Your project is set to: $PROJECT_ID" -ForegroundColor Cyan
Write-Host "You can now run: .\scripts\deploy.sh $PROJECT_ID" -ForegroundColor Yellow
