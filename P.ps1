# ==========================================================
# GODPROJECTH POWERSHELL LOADER
# PowerShell Loading UI + Run EXE
# KeyAuth อยู่ใน .exe ตามเดิม
# ==========================================================

$Host.UI.RawUI.WindowTitle = ">>==<< GODPROJECTH LOADER >>==<<"

$ExePath = ".\GODPROJECTH.exe"

$ErrorActionPreference = "SilentlyContinue"

function Set-ConsoleSize {
    try {
        $raw = $Host.UI.RawUI
        $buffer = $raw.BufferSize
        $window = $raw.WindowSize

        $buffer.Width = 100
        $buffer.Height = 3000
        $raw.BufferSize = $buffer

        $window.Width = 100
        $window.Height = 30
        $raw.WindowSize = $window
    } catch {}
}

function Write-Center {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White"
    )

    $width = $Host.UI.RawUI.WindowSize.Width
    $padding = [Math]::Max(0, [Math]::Floor(($width - $Text.Length) / 2))
    Write-Host (" " * $padding) -NoNewline
    Write-Host $Text -ForegroundColor $Color
}

function Write-Slow {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White",
        [int]$Delay = 15
    )

    foreach ($char in $Text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Draw-Line {
    param(
        [ConsoleColor]$Color = "DarkYellow"
    )

    Write-Host ""
    Write-Center "====================================================================" $Color
    Write-Host ""
}

function Show-Logo {
    Clear-Host
    Draw-Line DarkYellow

    Write-Center "   ██████╗  ██████╗ ██████╗ ██████╗ ██████╗  ██████╗      ██╗███████╗ ██████╗████████╗██╗  ██╗" Yellow
    Write-Center "  ██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗     ██║██╔════╝██╔════╝╚══██╔══╝██║  ██║" Yellow
    Write-Center "  ██║  ███╗██║   ██║██║  ██║██████╔╝██████╔╝██║   ██║     ██║█████╗  ██║        ██║   ███████║" Yellow
    Write-Center "  ██║   ██║██║   ██║██║  ██║██╔═══╝ ██╔══██╗██║   ██║██   ██║██╔══╝  ██║        ██║   ██╔══██║" Yellow
    Write-Center "  ╚██████╔╝╚██████╔╝██████╔╝██║     ██║  ██║╚██████╔╝╚█████╔╝███████╗╚██████╗   ██║   ██║  ██║" Yellow
    Write-Center "   ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝" Yellow

    Draw-Line DarkYellow

    Write-Center "[+] GODPROJECTH SECURE POWERSHELL LOADER [+]" Green
    Write-Center "[+] EXE KEYAUTH MODE ENABLED [+]" Cyan
    Write-Center "[+] LOADING DATA PLEASE WAIT [+]" White

    Draw-Line DarkYellow
}

function Show-Progress {
    param(
        [string]$Label,
        [int]$Duration = 800
    )

    $barLength = 40

    Write-Host ""
    Write-Host "   $Label" -ForegroundColor Cyan
    Write-Host "   [" -NoNewline -ForegroundColor DarkGray

    for ($i = 0; $i -le $barLength; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds ([Math]::Max(5, [int]($Duration / $barLength)))
    }

    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "OK" -ForegroundColor Green
}

function Spinner {
    param(
        [string]$Text,
        [int]$Seconds = 2
    )

    $frames = @("|", "/", "-", "\")
    $end = (Get-Date).AddSeconds($Seconds)
    $i = 0

    while ((Get-Date) -lt $end) {
        Write-Host "`r   $Text $($frames[$i % $frames.Count])" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
        $i++
    }

    Write-Host "`r   $Text DONE     " -ForegroundColor Green
}

function Check-Exe {
    if (!(Test-Path $ExePath)) {
        Write-Host ""
        Write-Host "   [FAIL] ไม่พบไฟล์ .exe" -ForegroundColor Red
        Write-Host "   Path ที่ตั้งไว้: $ExePath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   วิธีแก้:" -ForegroundColor Cyan
        Write-Host "   1. เอาไฟล์ GODPROJECTH.exe ไว้โฟลเดอร์เดียวกับ GODPROJECTH_LOADER.ps1"
        Write-Host "   2. หรือแก้บรรทัด `$ExePath ให้ตรงชื่อไฟล์จริง"
        Write-Host ""
        pause
        exit
    }
}

function Start-MainExe {
    Write-Host ""
    Write-Host "   [+] Starting GODPROJECTH.exe ..." -ForegroundColor Green
    Start-Sleep -Milliseconds 800

    try {
        Start-Process -FilePath $ExePath -WorkingDirectory (Split-Path -Parent (Resolve-Path $ExePath)) -Wait
    }
    catch {
        Write-Host ""
        Write-Host "   [FAIL] เปิด .exe ไม่ได้" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
        pause
        exit
    }
}

Set-ConsoleSize
Show-Logo

Spinner "Checking system" 1
Spinner "Loading protected modules" 1
Spinner "Preparing KeyAuth EXE session" 1

Show-Progress "Checking GODPROJECTH executable" 500
Check-Exe

Show-Progress "Loading user interface" 700
Show-Progress "Loading secure data" 900
Show-Progress "Preparing launch environment" 700

Write-Host ""
Write-Slow "   [+] ทุกอย่างพร้อมแล้ว กำลังเปิดโปรแกรมหลัก..." Green 20

Start-Sleep -Seconds 1
Start-MainExe

Write-Host ""
Write-Host "   [+] Program closed." -ForegroundColor Yellow
Start-Sleep -Seconds 1
