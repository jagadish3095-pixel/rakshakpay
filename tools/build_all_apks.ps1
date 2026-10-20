# Builds release APKs of all 9 RakshakPay apps into dist\ (share them by WhatsApp / Drive / USB).
# Every app talks to the cloud server. Usage:  tools\build_all_apks.cmd   [server URL]
param([string]$Server = "https://rakshakpay.onrender.com")
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
# arm64 + 32-bit arm covers almost every Android phone and keeps each APK small.
$common = @("--release", "--target-platform", "android-arm,android-arm64", "--dart-define=SERVER=$Server")

function Build($appDir, $outName, $extra = @()) {
    Write-Host "Building $outName..." -ForegroundColor Green
    Push-Location (Join-Path $root "apps\$appDir")
    try {
        flutter build apk @common @extra
        if ($LASTEXITCODE -ne 0) { throw "Build failed: $outName" }
        $flavor = if ($extra.Count) { "-" + $extra[1] } else { "" }
        Copy-Item "build\app\outputs\flutter-apk\app$flavor-release.apk" (Join-Path $dist "$outName.apk") -Force
    } finally {
        Pop-Location
    }
}

foreach ($b in @(("sahyadri", "Sahyadri-Bank"), ("ganga", "Ganga-Bank"), ("kaveri", "Kaveri-Bank"),
                 ("narmada", "Narmada-Bank"), ("godavari", "Godavari-Bank"))) {
    Build "bank_app" $b[1] @("--flavor", $b[0])
}
Build "upi_app" "RakshakPay"
Build "merchant_app" "RakshakPay-Business"
Build "crypto_app" "CoinVault"
Build "police_app" "Cyber-Police"

Write-Host "`nDone. APKs in $dist :" -ForegroundColor Green
Get-ChildItem $dist -Filter *.apk | ForEach-Object { "{0,-28} {1,6:N1} MB" -f $_.Name, ($_.Length / 1MB) }
