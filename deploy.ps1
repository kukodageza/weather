# Ensure running as Administrator
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You must run this script as an Administrator!" -ForegroundColor Red
    Start-Process powershell -Verb runAs -ArgumentList "-File `"$PSCommandPath`"" 
    Exit 0
}

# Ensure Kubernetes is running and kubeconfig is configured
Write-Host "Ensure Rancher Desktop is manually started, Kubernetes is enabled, and Nerdctl CLI is available before running this script."

# Add Rancher Desktop nerdctl to PATH
$rancherNerdctlPath = "C:\Program Files\Rancher Desktop\resources\resources\win32\bin"
if ($env:Path -notlike "*$rancherNerdctlPath*") {
    $env:Path += ";$rancherNerdctlPath"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Added Rancher Desktop nerdctl to PATH: $rancherNerdctlPath"
}

# Set the Kubernetes context to rancher-desktop
Write-Host "Setting Kubernetes context to rancher-desktop..."
kubectl config use-context rancher-desktop

# Wait and check Kubernetes status
Write-Host "Waiting for Kubernetes to start in Rancher Desktop..."
for ($i = 0; $i -lt 30; $i++) {
    if (kubectl get nodes --no-headers 2>$null) {
        Write-Host "Kubernetes is ready!"
        break
    } else {
        Start-Sleep -Seconds 10
        Write-Host "Checking Kubernetes status..."
    }
}
if (-not (kubectl get nodes --no-headers 2>$null)) {
    Write-Host "Kubernetes did not start in time. Exiting."
    exit 1
}

Write-Host "Rancher Desktop and Kubernetes are running."

# Install Helm if not already installed
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "Helm not found. Installing Helm..."
    $helmUri = "https://get.helm.sh/helm-v3.6.3-windows-amd64.zip"
    $helmZipPath = "$env:TEMP\helm.zip"
    $helmExtractPath = "$env:TEMP\helm"
    Invoke-WebRequest -Uri $helmUri -OutFile $helmZipPath
    Expand-Archive -Path $helmZipPath -DestinationPath $helmExtractPath
    Copy-Item -Path "$helmExtractPath\windows-amd64\helm.exe" -Destination "$env:ProgramFiles\helm\helm.exe"
    $env:Path += ";$env:ProgramFiles\helm"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Helm installed successfully."
} else {
    Write-Host "Helm is already installed."
}

# Ensure Kubernetes access and configuration
$kubeConfig = "$env:USERPROFILE\.kube\config"
if (-Not (Test-Path -Path $kubeConfig)) {
    Write-Host "Kubeconfig not found. Please ensure Kubernetes is configured correctly in Rancher Desktop and try again."
    exit 1
}

# Check Nerdctl CLI installation
if (-not (Get-Command nerdctl -ErrorAction SilentlyContinue)) {
    Write-Host "nerdctl not found in PATH. Please ensure nerdctl is available via Rancher Desktop and PATH is configured correctly."
    exit 1
}

# Build and push Docker images to the local registry (assuming nerdctl for containerd)
Write-Host "Building and pushing Docker images..."

# Ensure Nerdctl registry is running with HTTP support
try {
    $registryRunning = $(nerdctl ps --filter "name=registry" --quiet)
    if (-not $registryRunning) {
        Write-Host "Starting local Docker registry..."
        nerdctl run -d -p 5000:5000 --name registry --restart=always -e "REGISTRY_HTTP_ADDR=0.0.0.0:5000" registry:2
    } else {
        Write-Host "Local Docker registry is already running."
    }
} catch {
    Write-Host "Failed to start local registry."
    exit 1
}

# Build and push weather-api image with HTTP support
Write-Host "Building weather-api..."
cd weather_api
nerdctl build -t localhost:5000/weather-api:latest .
nerdctl push localhost:5000/weather-api:latest

# Build and push website-service image with HTTP support
Write-Host "Building website-service..."
cd ../website_service
nerdctl build -t localhost:5000/website-service:latest .
nerdctl push localhost:5000/website-service:latest

# Deploy using Helm
Write-Host "Deploying with Helm..."
cd ..
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Check if release exists
$releaseExists = helm ls --all --short | Select-String -Pattern "weather-app"
if ($releaseExists) {
    Write-Host "Existing Helm release found. Uninstalling..."
    helm uninstall weather-app
}

# Install Helm release
helm install weather-app ./k8s/helm/

# Install Prometheus and Grafana
Write-Host "Installing Prometheus and Grafana..."
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring

Write-Host "Deployment completed successfully."

# Run port-forward script
Write-Host "Starting port-forwarding for Prometheus and Grafana..."
.\port-forward.ps1