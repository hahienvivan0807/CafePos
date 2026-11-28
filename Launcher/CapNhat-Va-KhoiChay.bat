@echo off
chcp 65001 >nul
title Cap nhat build va khoi chay PinVuTru Cafe POS

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$root = (Resolve-Path (Join-Path '%~dp0' '..')).Path;" ^
  "Write-Host '=== CAP NHAT & BUILD LAI PINVUTRU CAFE POS ===' -ForegroundColor Yellow;" ^
  "Write-Host '[1/3] Dang dung CafePos.Api cu (neu dang chay)...' -ForegroundColor Cyan;" ^
  "$pids = (Get-NetTCPConnection -LocalPort 7179,5180 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique);" ^
  "foreach ($id in $pids) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue };" ^
  "Get-Process -Name 'CafePos.Api' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue;" ^
  "Start-Sleep -Seconds 1;" ^
  "Write-Host '[2/3] Dang build Backend (.NET 10)...' -ForegroundColor Cyan;" ^
  "Push-Location (Join-Path $root 'Backend'); dotnet build --nologo; Pop-Location;" ^
  "if ($LASTEXITCODE -ne 0) { Write-Host 'LOI BUILD BACKEND!' -ForegroundColor Red; exit 1 }" ^
  "Write-Host '[3/3] Dang build Frontend (Flutter Web)...' -ForegroundColor Cyan;" ^
  "Push-Location (Join-Path $root 'PosClient'); flutter build web --no-wasm-dry-run; Pop-Location;" ^
  "if ($LASTEXITCODE -ne 0) { Write-Host 'LOI BUILD FLUTTER WEB!' -ForegroundColor Red; exit 1 }" ^
  "Write-Host 'BUILD THANH CONG 100%%! Dang khoi chay lai he thong...' -ForegroundColor Green;"

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Co loi xay ra khi build. Nhan phim bat ky de dong...
  pause >nul
  exit /b 1
)

call "%~dp0KhoiChay-CafePOS.bat"
