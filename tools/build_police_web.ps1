# Builds the Cyber Police web app and puts it in backend/police_web,
# where the server serves it at /police (e.g. https://rakshakpay.onrender.com/police).
# Commit and push backend/police_web afterwards so Render serves the new version.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$app = Join-Path $root "apps\police_app"
$out = Join-Path $root "backend\police_web"

Push-Location $app
try {
    flutter build web --base-href /police/ --release
    if ($LASTEXITCODE -ne 0) { throw "Web build failed" }
} finally {
    Pop-Location
}
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
Copy-Item -Recurse (Join-Path $app "build\web") $out
# Flutter loads its rendering engine (CanvasKit) from Google's CDN by default, so the
# 36 MB local copy is not needed and is left out to keep the repository small.
Remove-Item -Recurse -Force (Join-Path $out "canvaskit")
Write-Host "Police web app copied to $out" -ForegroundColor Green
