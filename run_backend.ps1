# Starts the RakshakPay banking network on this laptop.
# Phones on the same Wi-Fi connect to http://<this laptop's IP>:8000
$ErrorActionPreference = "Stop"
$backend = Join-Path $PSScriptRoot "backend"

$ips = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object -ExpandProperty IPAddress
Write-Host ""
Write-Host "RakshakPay server starting..." -ForegroundColor Green
Write-Host "Enter one of these in each app's Settings > Server address:" -ForegroundColor Yellow
foreach ($ip in $ips) { Write-Host "   http://${ip}:8000" }
Write-Host "API docs (try every API in the browser): http://localhost:8000/docs"
Write-Host ""

& "$backend\.venv\Scripts\python.exe" -m uvicorn app.main:app --app-dir $backend --host 0.0.0.0 --port 8000 --reload --reload-dir "$backend\app"
