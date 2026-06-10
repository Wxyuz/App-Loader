# ==========================================================
# GODPROJECTH POWERSHELL LOADER
# Auto Download loader.exe + Open GUI
# Works with: irm "LINK" | iex
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = ">>==<< GODPROJECTH LOADER >>==<<"

$ExeName = "loader.exe"

# ใส่ลิงก์โหลด loader.exe ตรงนี้
# แนะนำให้อัป loader.exe ไว้ใน GitHub Releases แล้วเอาลิงก์มาใส่
$ExeDownloadUrl = "https://github.com/Wxyuz/App-Loader/releases/download/v1.0/loader.exe"

$InstallFolder = Join-Path $env:LOCALAPPDATA "GODPROJECTH"
$ExePath = Join-Path $InstallFolder $ExeName

function Write-Center {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White"
    )

    $Width = $Host.UI.RawUI.WindowSize.Width
    $Pad = [Math]::Max(0, [Math]::Floor(($Width - $Text.Length) / 2))
    Write-Host (" " * $Pad) -NoNewline
    Write-Host $Text -ForegroundColor $Color
}

function Show-Logo {
    Clear-Host
    Write-Center "============================================================" Cyan
    Write-Host ""
    Write-Center " ██████╗  ██████╗ ██████╗ ██████╗ ██████╗  ██████╗ " Yellow
    Write-Center "██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗" Yellow
    Write-Center "██║  ███╗██║   ██║██║  ██║██████╔╝██████╔╝██║   ██║" Yellow
    Write-Center "██║   ██║██║   ██║██║  ██║██╔═══╝ ██╔══██╗██║   ██║" Yellow
    Write-Center "╚██████╔╝╚██████╔╝██████╔╝██║     ██║  ██║╚██████╔╝" Yellow
    Write-Center " ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝ " Yellow
    Write-Host ""
    Write-Center "GODPROJECTH LOADER" Green
    Write-Center "LOADING DATA PLEASE WAIT" White
    Write-Host ""
    Write-Center "============================================================" Cyan
    Write-Host ""
}

function Step {
    param([string]$Text)

    Write-Host " $Text " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 450
    Write-Host "DONE" -ForegroundColor Green
}

function Progress {
    param([string]$Text)

    Write-Host ""
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host " [" -NoNewline -ForegroundColor DarkGray

    for ($i = 0; $i -lt 45; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 10
    }

    Write-Host "] OK" -ForegroundColor Green
}

function Prepare-Folder {
    if (!(Test-Path $InstallFolder)) {
        New-Item -ItemType Directory -Path $InstallFolder -Force | Out-Null
    }
}

function Download-Exe {
    Write-Host ""
    Write-Host " [!] loader.exe not found" -ForegroundColor Yellow
    Write-Host " [+] Downloading loader.exe..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest `
            -Uri $ExeDownloadUrl `
            -OutFile $ExePath `
            -UseBasicParsing `
            -TimeoutSec 60

        if (!(Test-Path $ExePath)) {
            throw "Download failed"
        }

        Write-Host " [+] Download complete" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host " [FAIL] Cannot download loader.exe" -ForegroundColor Red
        Write-Host " URL: $ExeDownloadUrl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Fix:" -ForegroundColor Cyan
        Write-Host "1. Upload loader.exe to GitHub Releases"
        Write-Host "2. Copy direct download link"
        Write-Host "3. Put it in `$ExeDownloadUrl"
        Write-Host ""
        pause
        exit
    }
}

function Start-GUI {
    if (!(Test-Path $ExePath)) {
        Download-Exe
    }

    Write-Host ""
    Write-Host " [+] Opening GUI loader.exe..." -ForegroundColor Green
    Start-Sleep -Milliseconds 800

    Start-Process -FilePath $ExePath -WorkingDirectory $InstallFolder
    exit
}

Show-Logo

Step "Checking system"
Step "Loading protected modules"
Step "Preparing GUI session"

Prepare-Folder

Progress "Checking loader.exe"

if (!(Test-Path $ExePath)) {
    Download-Exe
}

Progress "Loading user interface"
Progress "Loading secure data"
Progress "Preparing launch environment"

Start-GUI
