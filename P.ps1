# ==========================================================
# GODPROJECTH POWERSHELL LOADER
# ใช้กับ irm "ลิงก์ P.ps1" | iex
# โหลด/เปิด loader.exe อัตโนมัติ
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = ">>==<< GODPROJECTH LOADER >>==<<"

# ชื่อไฟล์ GUI
$ExeName = "loader.exe"

# ลิงก์โหลด loader.exe
# แก้เป็นลิงก์ไฟล์ loader.exe ของคุณเอง
$ExeDownloadUrl = "https://raw.githubusercontent.com/Wxyuz/App-Loader/main/loader.exe"

# โฟลเดอร์ติดตั้งในเครื่อง
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
    Write-Center "GODPROJECTH SECURE POWERSHELL LOADER" Green
    Write-Center "LOADING DATA PLEASE WAIT" White
    Write-Host ""
    Write-Center "============================================================" Cyan
    Write-Host ""
}

function Step {
    param(
        [string]$Text,
        [int]$Delay = 450
    )

    Write-Host " $Text " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds $Delay
    Write-Host "DONE" -ForegroundColor Green
}

function Progress {
    param(
        [string]$Text,
        [int]$Speed = 8
    )

    Write-Host ""
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host " [" -NoNewline -ForegroundColor DarkGray

    for ($i = 0; $i -lt 45; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds $Speed
    }

    Write-Host "] OK" -ForegroundColor Green
}

function Prepare-Folder {
    if (!(Test-Path $InstallFolder)) {
        New-Item -ItemType Directory -Path $InstallFolder -Force | Out-Null
    }
}

function Download-Loader {
    Write-Host ""
    Write-Host " [!] loader.exe not found" -ForegroundColor Yellow
    Write-Host " [+] Downloading loader.exe..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest `
            -Uri $ExeDownloadUrl `
            -OutFile $ExePath `
            -UseBasicParsing `
            -TimeoutSec 90

        if (!(Test-Path $ExePath)) {
            throw "File not downloaded"
        }

        $FileSize = (Get-Item $ExePath).Length

        if ($FileSize -lt 10000) {
            Remove-Item $ExePath -Force
            throw "Downloaded file is too small. Link may be wrong."
        }

        Write-Host " [+] Download complete" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host " [FAIL] โหลด loader.exe ไม่สำเร็จ" -ForegroundColor Red
        Write-Host " URL: $ExeDownloadUrl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "วิธีแก้:" -ForegroundColor Cyan
        Write-Host "1. ต้องมีไฟล์ loader.exe อยู่ใน GitHub repo"
        Write-Host "2. ลิงก์ต้องเปิดแล้วเป็นไฟล์ exe จริง"
        Write-Host "3. ห้ามใช้ลิงก์หน้าเว็บ GitHub ปกติ ต้องใช้ raw หรือ releases"
        Write-Host ""
        pause
        exit
    }
}

function Start-Loader {
    if (!(Test-Path $ExePath)) {
        Download-Loader
    }

    Write-Host ""
    Write-Host " [+] Loading complete" -ForegroundColor Green
    Write-Host " [+] Opening loader.exe..." -ForegroundColor Green
    Start-Sleep -Milliseconds 700

    try {
        Start-Process -FilePath $ExePath -WorkingDirectory $InstallFolder
        exit
    }
    catch {
        Write-Host ""
        Write-Host " [FAIL] เปิด loader.exe ไม่ได้" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        pause
        exit
    }
}

Show-Logo

Step "Checking system"
Step "Loading protected modules"
Step "Preparing GUI session"

Prepare-Folder

Progress "Checking loader.exe"

if (!(Test-Path $ExePath)) {
    Download-Loader
}

Progress "Loading user interface"
Progress "Loading secure data"
Progress "Preparing launch environment"

Start-Loader
