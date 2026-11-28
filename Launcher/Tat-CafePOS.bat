@echo off
chcp 65001 >nul
title Tat PinVuTru Cafe POS (Giai phong RAM & GPU)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Write-Host '=== DANG TAT PINVUTRU CAFE POS ===' -ForegroundColor Yellow;" ^
  "$pids = (Get-NetTCPConnection -LocalPort 7179,5180 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique);" ^
  "foreach ($id in $pids) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue; Write-Host ('Da tat CafePos.Api (PID ' + $id + ')') -ForegroundColor Green; };" ^
  "foreach ($name in @('CafePos.Api', 'ngrok', 'ollama', 'ollama app')) {" ^
  "  $procs = Get-Process -Name $name -ErrorAction SilentlyContinue;" ^
  "  if ($procs) { $procs | Stop-Process -Force -ErrorAction SilentlyContinue; Write-Host ('Da tat ' + $name) -ForegroundColor Green; }" ^
  "}" ^
  "Write-Host 'Da tat sach se CafePos.Api, ngrok va Ollama (da giai phong RAM/GPU).' -ForegroundColor Cyan;"
timeout /t 3 >nul
