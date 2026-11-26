$ErrorActionPreference = 'SilentlyContinue'

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$publishDir = Join-Path $baseDir 'publish'
$exePath = Join-Path $publishDir 'CafePosTracker.exe'
$appUrl = 'http://localhost:5178'
$healthUrl = "$appUrl/health"

function Test-ServerReady {
    try {
        $resp = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 2
        return $resp.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

if (-not (Test-ServerReady)) {
    if (-not (Test-Path $exePath)) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "Không tìm thấy bản publish tại:`n$exePath`n`nHãy chạy lệnh dotnet publish trước.",
            "Theo dõi dự án POS quán cà phê",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        exit 1
    }

    Start-Process -FilePath $exePath -WorkingDirectory $publishDir -WindowStyle Hidden | Out-Null

    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline) {
        if (Test-ServerReady) {
            break
        }
        Start-Sleep -Milliseconds 250
    }
}

Start-Process $appUrl | Out-Null
