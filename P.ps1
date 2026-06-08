$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$AppName = "App-Loader"
$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"

$TempFolder = Join-Path $env:TEMP $AppName
$OutFile = Join-Path $TempFolder $FileName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Show-ProgressBar {
    param(
        [int]$Percent
    )

    if ($Percent -lt 0) {
        $Percent = 0
    }

    if ($Percent -gt 100) {
        $Percent = 100
    }

    $BarWidth = 45
    $FilledCount = [math]::Floor(($Percent / 100) * $BarWidth)
    $EmptyCount = $BarWidth - $FilledCount

    $FilledBar = ""
    $EmptyBar = ""

    if ($FilledCount -gt 0) {
        $FilledBar = "#" * $FilledCount
    }

    if ($EmptyCount -gt 0) {
        $EmptyBar = "-" * $EmptyCount
    }

    $Line = "App-Loader [$FilledBar$EmptyBar] $Percent%"

    try {
        $ConsoleWidth = [Console]::WindowWidth - 1
    }
    catch {
        $ConsoleWidth = 80
    }

    if ($Line.Length -gt $ConsoleWidth) {
        $Line = $Line.Substring(0, $ConsoleWidth)
    }

    $PaddingLength = $ConsoleWidth - $Line.Length

    if ($PaddingLength -lt 0) {
        $PaddingLength = 0
    }

    $Padding = " " * $PaddingLength

    Write-Host -NoNewline "`r$Line$Padding"
}

function Close-Safe {
    param(
        $Object
    )

    if ($null -ne $Object) {
        try {
            $Object.Close()
        }
        catch {
        }

        try {
            $Object.Dispose()
        }
        catch {
        }
    }
}

function Close-ThisPowerShell {
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }

    Start-Sleep -Milliseconds 300

    try {
        Stop-Process -Id $PID -Force
    }
    catch {
        exit
    }
}

$Response = $null
$InputStream = $null
$OutputStream = $null

try {
    Clear-Host

    try {
        $Host.UI.RawUI.WindowTitle = "App-Loader"
    }
    catch {
    }

    try {
        [Console]::CursorVisible = $false
    }
    catch {
    }

    if (!(Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }

    if (Test-Path $OutFile) {
        Remove-Item -Path $OutFile -Force
    }

    Show-ProgressBar -Percent 0

    $Request = [System.Net.HttpWebRequest]::Create($ExeUrl)
    $Request.Method = "GET"
    $Request.AllowAutoRedirect = $true
    $Request.UserAgent = "App-Loader"
    $Request.Timeout = 30000
    $Request.ReadWriteTimeout = 30000

    $Response = $Request.GetResponse()
    $TotalBytes = [int64]$Response.ContentLength

    $InputStream = $Response.GetResponseStream()
    $OutputStream = [System.IO.File]::Create($OutFile)

    $Buffer = New-Object byte[] 65536
    $TotalRead = 0
    $Percent = 0
    $LastPercent = -1

    while ($true) {
        $Read = $InputStream.Read($Buffer, 0, $Buffer.Length)

        if ($Read -le 0) {
            break
        }

        $OutputStream.Write($Buffer, 0, $Read)
        $TotalRead += $Read

        if ($TotalBytes -gt 0) {
            $Percent = [int][math]::Floor(($TotalRead / $TotalBytes) * 100)
        }
        else {
            if ($Percent -lt 95) {
                $Percent = $Percent + 1
            }
        }

        if ($Percent -ne $LastPercent) {
            Show-ProgressBar -Percent $Percent
            $LastPercent = $Percent
        }
    }

    Close-Safe -Object $OutputStream
    Close-Safe -Object $InputStream
    Close-Safe -Object $Response

    Show-ProgressBar -Percent 100
    Start-Sleep -Milliseconds 500

    if (!(Test-Path $OutFile)) {
        throw "loader.exe not found after download."
    }

    $FileInfo = Get-Item $OutFile

    if ($FileInfo.Length -le 0) {
        throw "loader.exe is empty."
    }

    Clear-Host
    Show-ProgressBar -Percent 100
    Start-Sleep -Milliseconds 400

    Start-Process -FilePath $OutFile -WorkingDirectory $TempFolder

    Start-Sleep -Milliseconds 800

    Close-ThisPowerShell
}
catch {
    Close-Safe -Object $OutputStream
    Close-Safe -Object $InputStream
    Close-Safe -Object $Response

    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }

    Clear-Host
    Write-Host ""
    Write-Host "App-Loader failed."
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Start-Sleep -Seconds 5

    Close-ThisPowerShell
}
