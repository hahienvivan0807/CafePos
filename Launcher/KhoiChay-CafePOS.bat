@echo off
chcp 65001 >nul
title Khoi chay PinVuTru Cafe POS (AI + VietQR)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Continue';" ^
  "$root = (Resolve-Path (Join-Path '%~dp0' '..')).Path;" ^
  "$envFile = Join-Path $root '.env';" ^
  "$cfg = @{};" ^
  "if (Test-Path $envFile) {" ^
  "  Get-Content $envFile | ForEach-Object {" ^
  "    $line = $_.Trim();" ^
  "    if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {" ^
  "      $idx = $line.IndexOf('=');" ^
  "      $k = $line.Substring(0, $idx).Trim();" ^
  "      $v = $line.Substring($idx + 1).Trim().Trim('\"').Trim(\"'\");" ^
  "      if ($k -and $v) { $cfg[$k] = $v; [Environment]::SetEnvironmentVariable($k, $v, 'Process') }" ^
  "    }" ^
  "  }" ^
  "}" ^
  "Write-Host '=== KHOI CHAY PINVUTRU CAFE POS ===' -ForegroundColor Green;" ^
  "function Test-Port($p) { try { $c = New-Object Net.Sockets.TcpClient; $ar = $c.BeginConnect('127.0.0.1', $p, $null, $null); $ok = $ar.AsyncWaitHandle.WaitOne(400); $c.Close(); return $ok } catch { return $false } }" ^
  "$ollamaModels = if ($cfg.ContainsKey('OLLAMA_MODELS')) { $cfg['OLLAMA_MODELS'] } else { 'D:\AI_Models\ollama' };" ^
  "if (-not (Test-Port 11434)) {" ^
  "  Write-Host ('[1/3] Dang bat Ollama AI (' + $ollamaModels + ')...') -ForegroundColor Cyan;" ^
  "  $ollamaExe = 'D:\Tools\Ollama\ollama.exe';" ^
  "  if (-not (Test-Path $ollamaExe)) { $ollamaExe = 'ollama' };" ^
  "  $env:OLLAMA_MODELS = $ollamaModels;" ^
  "  Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Minimized;" ^
  "} else { Write-Host '[1/3] Ollama AI da chay san (cong 11434).' -ForegroundColor DarkGray; }" ^
  "if (-not (Test-Port 4040)) {" ^
  "  $ngrokDomain = if ($cfg.ContainsKey('NGROK_DOMAIN')) { $cfg['NGROK_DOMAIN'] } else { '' };" ^
  "  $ngrokArgs = if ($ngrokDomain) { 'http http://localhost:5180 --url ' + $ngrokDomain } else { 'http http://localhost:5180' };" ^
  "  Write-Host ('[2/3] Dang bat ngrok VietQR (' + $ngrokArgs + ')...') -ForegroundColor Cyan;" ^
  "  Start-Process -FilePath 'ngrok' -ArgumentList $ngrokArgs -WindowStyle Minimized;" ^
  "} else { Write-Host '[2/3] ngrok da chay san (cong 4040).' -ForegroundColor DarkGray; }" ^
  "if (-not (Test-Port 7179)) {" ^
  "  Write-Host '[3/3] Dang bat CafePos.Api (https://localhost:7179)...' -ForegroundColor Cyan;" ^
  "  $apiDir = Join-Path $root 'Backend\CafePos.Api';" ^
  "  $dll = Join-Path $apiDir 'bin\Debug\net10.0\CafePos.Api.dll';" ^
  "  $runArgs = if (Test-Path $dll) { 'run --no-build' } else { 'run' };" ^
  "  Start-Process -FilePath 'dotnet' -ArgumentList $runArgs -WorkingDirectory $apiDir -WindowStyle Minimized;" ^
  "} else { Write-Host '[3/3] CafePos.Api da chay san (cong 7179).' -ForegroundColor DarkGray; }" ^
  "Write-Host 'Dang cho he thong san sang...' -ForegroundColor Yellow;" ^
  "$ready = $false;" ^
  "for ($i = 0; $i -lt 30; $i++) {" ^
  "  Start-Sleep -Seconds 1;" ^
  "  try { $r = Invoke-RestMethod -Uri 'http://127.0.0.1:5180/api/health' -TimeoutSec 2; if ($r.status -eq 'Healthy') { $ready = $true; break } } catch {}" ^
  "}" ^
  "if ($ready) {" ^
  "  Write-Host 'HE THONG SAN SANG! Dang mo https://localhost:7179/' -ForegroundColor Green;" ^
  "  Start-Process 'https://localhost:7179/';" ^
  "} else {" ^
  "  Write-Host 'CafePos.Api khoi dong hoi lau, dang mo trinh duyet...' -ForegroundColor Yellow;" ^
  "  Start-Process 'https://localhost:7179/';" ^
  "}"
timeout /t 3 >nul
