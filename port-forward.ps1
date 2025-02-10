# Function to stop processes using specific ports
function Stop-PortProcess {
    param (
        [int]$Port
    )
    $processes = netstat -ano | Select-String ":$Port" | ForEach-Object {
        $_.ToString().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[-1]
    }
    foreach ($processId in $processes) {
        try {
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "Stopped process with PID $processId using port $Port"
        } catch {
            Write-Host "Failed to stop process with PID $processId using port $Port"
        }
    }
}

# Stop processes using ports 3000 and 9090
Stop-PortProcess -Port 3000
Stop-PortProcess -Port 9090

# Wait a moment to ensure processes are fully stopped
Start-Sleep -Seconds 5

# Start port-forwarding for Prometheus and Grafana
kubectl port-forward svc/prometheus 9090:9090 &
kubectl port-forward svc/grafana 3000:3000 &