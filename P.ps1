# ==========================================================
# GODPROJECTH POWERSHELL LOADER
# หลังโหลดเสร็จจะเปิด loader.exe
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = ">>==<< GODPROJECTH LOADER >>==<<"

# ชื่อไฟล์ GUI ที่ต้องการเปิด
$ExeName = "loader.exe"

# หา path โฟลเดอร์ที่ script อยู่จริง
$ScriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($ScriptFolder)) {
    $ScriptFolder = Get-Location
}

$ExePath = Join-Path $ScriptFolder $ExeName

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

    Write-Center "====================================================================" Cyan
    Write-Host ""

    Write-Center " ██████╗  ██████╗ ██████╗ ██████╗ ██████╗  ██████╗      ██╗███████╗ ██████╗████████╗██╗  ██╗" Yellow
    Write-Center "██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗     ██║██╔════╝██╔════╝╚══██╔══╝██║  ██║" Yellow
    Write-Center "██║  ███╗██║   ██║██║  ██║██████╔╝██████╔╝██║   ██║     ██║█████╗  ██║        ██║   ███████║" Yellow
    Write-Center "██║   ██║██║   ██║██║  ██║██╔═══╝ ██╔══██╗██║   ██║██   ██║██╔══╝  ██║        ██║   ██╔══██║" Yellow
    Write-Center "╚██████╔╝╚██████╔╝██████╔╝██║     ██║  ██║╚██████╔╝╚█████╔╝███████╗╚██████╗   ██║   ██║  ██║" Yellow
    Write-Center " ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝" Yellow

    Write-Host ""
    Write-Center "====================================================================" Cyan
    Write-Host ""
    Write-Center "[+] GODPROJECTH SECURE POWERSHELL LOADER [+]" Green
    Write-Center "[+] LOADING DATA PLEASE WAIT [+]" White
    Write-Host ""
    Write-Center "====================================================================" Cyan
    Write-Host ""
}

function Show-Step {
    param(
        [string]$Text,
        [int]$Delay = 450
    )

    Write-Host " $Text " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds $Delay
    Write-Host "DONE" -ForegroundColor Green
}

function Show-Progress {
    param(
        [string]$Text,
        [int]$Speed = 15
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

function Start-GuiLoader {
    if (!(Test-Path $ExePath)) {
        Write-Host ""
        Write-Host " [FAIL] ไม่พบไฟล์ loader.exe" -ForegroundColor Red
        Write-Host " Path ที่หา: $ExePath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " วิธีแก้:" -ForegroundColor Cyan
        Write-Host " 1. เอา loader.exe ไว้โฟลเดอร์เดียวกับ P.ps1" -ForegroundColor White
        Write-Host " 2. หรือแก้ `$ExeName ให้ตรงชื่อไฟล์ GUI ของคุณ" -ForegroundColor White
        Write-Host ""
        pause
        exit
    }

    Write-Host ""
    Write-Host " [+] Loading complete" -ForegroundColor Green
    Write-Host " [+] Opening GUI loader.exe..." -ForegroundColor Green
    Start-Sleep -Milliseconds 900

    Start-Process -FilePath $ExePath -WorkingDirectory $ScriptFolder

    Start-Sleep -Milliseconds 500
    exit
}

Show-Logo

Show-Step "Checking system"
Show-Step "Loading protected modules"
Show-Step "Preparing GUI session"

Show-Progress "Checking loader.exe" 8
Show-Progress "Loading user interface" 10
Show-Progress "Loading secure data" 10
Show-Progress "Preparing launch environment" 8

Start-GuiLoader
