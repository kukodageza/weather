Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward --namespace monitoring svc/prometheus-server 9090:80"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward --namespace monitoring svc/grafana 3000:80"