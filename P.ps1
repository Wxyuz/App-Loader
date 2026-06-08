$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"
$TempFolder = Join-Path $env:TEMP "App-Loader"
$OutFile = Join-Path $TempFolder $FileName

Write-Host "====================================="
Write-Host " App-Loader"
Write-Host "====================================="
Write-Host ""

if (!(Test-Path $TempFolder)) {
    New-Item -ItemType Directory -Path $TempFolder | Out-Null
}

Write-Host "[1/3] Downloading loader.exe..."
Write-Host "URL: $ExeUrl"
Write-Host ""

try {
    Invoke-WebRequest -Uri $ExeUrl -OutFile $OutFile -UseBasicParsing
}
catch {
    Write-Host "Download failed."
    Write-Host $_.Exception.Message
    pause
    exit
}

if (!(Test-Path $OutFile)) {
    Write-Host "File not found after download."
    pause
    exit
}

Write-Host ""
Write-Host "[2/3] Download completed."
Write-Host "Saved to: $OutFile"
Write-Host ""

Write-Host "SHA256:"
Get-FileHash -Path $OutFile -Algorithm SHA256

Write-Host ""
Write-Host "[3/3] Starting loader.exe..."
Start-Process -FilePath $OutFile

Write-Host ""
Write-Host "Done."
