# Function to stop processes using specific ports
function Stop-PortProcess {
    param (
        [int]$Port
    )
    $processes = netstat -ano | Select-String ":$Port" | ForEach-Object {
        $_.ToString().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[-1]
    }
    foreach ($pid in $processes) {
        try {
            Stop-Process -Id $pid -Force -ErrorAction Stop
            Write-Host "Stopped process with PID $pid using port $Port"
        } catch {
            Write-Host "Failed to stop process with PID $pid using port $Port"
        }
    }
}

# Stop processes using ports 3000 and 9090
Stop-PortProcess -Port 3000
Stop-PortProcess -Port 9090

# Start port-forwarding for Prometheus and Grafana
kubectl port-forward svc/prometheus 9090:9090 &
kubectl port-forward svc/grafana 3000:3000 &