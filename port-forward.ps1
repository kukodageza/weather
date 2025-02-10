# Start port-forwarding for Prometheus and Grafana
Write-Host "Starting port-forwarding for Prometheus and Grafana..."

# Forward Grafana port
Start-Job -ScriptBlock {
    kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 --namespace monitoring
}

# Forward Prometheus port
Start-Job -ScriptBlock {
    kubectl port-forward svc/prometheus-grafana 3000:80 --namespace monitoring
}

Write-Host "Port-forwarding started."