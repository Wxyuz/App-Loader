$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$AppName = "App-Loader"
$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"

$TempFolder = Join-Path $env:TEMP $AppName
$OutFile = Join-Path $TempFolder $FileName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Show-LoadingBar {
    param(
        [int]$Percent,
        [string]$Text
    )

    if ($Percent -lt 0) {
        $Percent = 0
    }

    if ($Percent -gt 100) {
        $Percent = 100
    }

    $BarSize = 35
    $FilledSize = [math]::Floor(($Percent / 100) * $BarSize)
    $EmptySize = $BarSize - $FilledSize

    $FilledBar = ""
    $EmptyBar = ""

    if ($FilledSize -gt 0) {
        $FilledBar = "█" * $FilledSize
    }

    if ($EmptySize -gt 0) {
        $EmptyBar = "░" * $EmptySize
    }

    Write-Host -NoNewline "`r$Text [$FilledBar$EmptyBar] $Percent%"
}

function Close-AllStreams {
    param(
        $ResponseStream,
        $FileStream,
        $Response
    )

    if ($ResponseStream -ne $null) {
        $ResponseStream.Close()
        $ResponseStream.Dispose()
    }

    if ($FileStream -ne $null) {
        $FileStream.Close()
        $FileStream.Dispose()
    }

    if ($Response -ne $null) {
        $Response.Close()
        $Response.Dispose()
    }
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "App-Loader"

if (!(Test-Path $TempFolder)) {
    New-Item -ItemType Directory -Path $TempFolder | Out-Null
}

if (Test-Path $OutFile) {
    Remove-Item -Path $OutFile -Force
}

$Response = $null
$ResponseStream = $null
$FileStream = $null

try {
    Show-LoadingBar -Percent 0 -Text "Loading"

    $Request = [System.Net.HttpWebRequest]::Create($ExeUrl)
    $Request.Method = "GET"
    $Request.AllowAutoRedirect = $true
    $Request.UserAgent = "App-Loader"
    $Request.Timeout = 30000
    $Request.ReadWriteTimeout = 30000

    $Response = $Request.GetResponse()
    $TotalBytes = $Response.ContentLength

    $ResponseStream = $Response.GetResponseStream()
    $FileStream = [System.IO.File]::Create($OutFile)

    $Buffer = New-Object byte[] 81920
    $TotalRead = 0
    $LastPercent = -1

    while ($true) {
        $Read = $ResponseStream.Read($Buffer, 0, $Buffer.Length)

        if ($Read -le 0) {
            break
        }

        $FileStream.Write($Buffer, 0, $Read)
        $TotalRead += $Read

        if ($TotalBytes -gt 0) {
            $Percent = [int](($TotalRead / $TotalBytes) * 100)
        }
        else {
            $Percent = ($Percent + 3) % 100
        }

        if ($Percent -ne $LastPercent) {
            Show-LoadingBar -Percent $Percent -Text "Loading"
            $LastPercent = $Percent
        }
    }

    Close-AllStreams -ResponseStream $ResponseStream -FileStream $FileStream -Response $Response

    Show-LoadingBar -Percent 100 -Text "Loading"
    Start-Sleep -Milliseconds 500
}
catch {
    Close-AllStreams -ResponseStream $ResponseStream -FileStream $FileStream -Response $Response

    Clear-Host
    Write-Host ""
    Write-Host "Download failed"
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Pause
    exit
}

if (!(Test-Path $OutFile)) {
    Clear-Host
    Write-Host ""
    Write-Host "loader.exe not found"
    Write-Host ""
    Pause
    exit
}

$FileInfo = Get-Item $OutFile

if ($FileInfo.Length -le 0) {
    Clear-Host
    Write-Host ""
    Write-Host "loader.exe is empty"
    Write-Host ""
    Pause
    exit
}

try {
    Clear-Host
    Show-LoadingBar -Percent 100 -Text "Ready"
    Start-Sleep -Milliseconds 300

    Start-Process -FilePath $OutFile -WorkingDirectory $TempFolder

    Start-Sleep -Milliseconds 700
    exit
}
catch {
    Clear-Host
    Write-Host ""
    Write-Host "Cannot start loader.exe"
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Pause
    exit
}
