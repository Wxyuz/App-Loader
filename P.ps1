$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = ">>==<< GODPROJECTH LOADER >>==<<"

$ExeName = "loader.exe"
$ExeDownloadUrl = "https://github.com/Wxyuz/App-Loader/releases/download/v1.0/loader.exe"

$InstallFolder = Join-Path $env:LOCALAPPDATA "GODPROJECTH"
$ExePath = Join-Path $InstallFolder $ExeName

function Step($Text) {
    Write-Host "$Text " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 350
    Write-Host "DONE" -ForegroundColor Green
}

function Progress($Text) {
    Write-Host ""
    Write-Host "$Text" -ForegroundColor Cyan
    Write-Host "[" -NoNewline -ForegroundColor DarkGray

    for ($i = 0; $i -lt 45; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 8
    }

    Write-Host "] OK" -ForegroundColor Green
}

function Show-Logo {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " ██████╗  ██████╗ ██████╗ ██████╗ ██████╗  ██████╗ " -ForegroundColor Yellow
    Write-Host "██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗" -ForegroundColor Yellow
    Write-Host "██║  ███╗██║   ██║██║  ██║██████╔╝██████╔╝██║   ██║" -ForegroundColor Yellow
    Write-Host "██║   ██║██║   ██║██║  ██║██╔═══╝ ██╔══██╗██║   ██║" -ForegroundColor Yellow
    Write-Host "╚██████╔╝╚██████╔╝██████╔╝██║     ██║  ██║╚██████╔╝" -ForegroundColor Yellow
    Write-Host " ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor Yellow
    Write-Host "GODPROJECTH SECURE POWERSHELL LOADER" -ForegroundColor Green
    Write-Host "LOADING DATA PLEASE WAIT" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Prepare-Folder {
    if (!(Test-Path $InstallFolder)) {
        New-Item -ItemType Directory -Path $InstallFolder -Force | Out-Null
    }
}

function Download-Loader {
    Write-Host ""
    Write-Host "[!] loader.exe not found" -ForegroundColor Yellow
    Write-Host "[+] Downloading loader.exe..." -ForegroundColor Cyan
    Write-Host "URL: $ExeDownloadUrl" -ForegroundColor Yellow

    try {
        Invoke-WebRequest `
            -Uri $ExeDownloadUrl `
            -OutFile $ExePath `
            -UseBasicParsing `
            -TimeoutSec 120
    }
    catch {
        Write-Host ""
        Write-Host "[FAIL] โหลด loader.exe ไม่สำเร็จ" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""
        Write-Host "สาเหตุ: ยังไม่ได้อัป loader.exe ไปที่ GitHub Releases หรือ tag ไม่ใช่ v1.0" -ForegroundColor Cyan
        pause
        exit
    }

    if (!(Test-Path $ExePath)) {
        Write-Host "[FAIL] โหลดแล้วแต่ไม่พบไฟล์" -ForegroundColor Red
        pause
        exit
    }

    $Size = (Get-Item $ExePath).Length

    if ($Size -lt 100000) {
        Remove-Item $ExePath -Force -ErrorAction SilentlyContinue
        Write-Host "[FAIL] ไฟล์ที่โหลดมาเล็กผิดปกติ ลิงก์ไม่ใช่ .exe จริง" -ForegroundColor Red
        pause
        exit
    }

    Write-Host "[+] Download complete" -ForegroundColor Green
}

function Start-Loader {
    if (!(Test-Path $ExePath)) {
        Download-Loader
    }

    Progress "Loading user interface"
    Progress "Loading secure data"
    Progress "Preparing launch environment"

    Write-Host ""
    Write-Host "[+] Opening loader.exe..." -ForegroundColor Green

    Start-Process -FilePath $ExePath -WorkingDirectory $InstallFolder
    exit
}

Show-Logo
Step "Checking system"
Step "Loading protected modules"
Step "Preparing GUI session"

Prepare-Folder
Progress "Checking loader.exe"

Start-Loader
