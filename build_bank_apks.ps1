# Builds all 5 bank apps and copies the APKs to dist\
$ErrorActionPreference = "Stop"
$app = Join-Path $PSScriptRoot "apps\bank_app"
$dist = Join-Path $PSScriptRoot "dist"
New-Item -ItemType Directory -Force $dist | Out-Null

Push-Location $app
try {
    foreach ($bank in "sahyadri", "ganga", "kaveri", "narmada", "godavari") {
        Write-Host "Building $bank..." -ForegroundColor Green
        flutter build apk --release --flavor $bank
        if ($LASTEXITCODE -ne 0) { throw "Build failed for $bank" }
        Copy-Item "build\app\outputs\flutter-apk\app-$bank-release.apk" "$dist\$bank-bank.apk" -Force
    }
} finally {
    Pop-Location
}
Write-Host "Done. APKs are in $dist" -ForegroundColor Green
