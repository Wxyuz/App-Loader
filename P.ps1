$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$AppName = "App-Loader"
$ScriptVersion = "RAW-RUN-GUI-V901"

$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"

$TempFolder = Join-Path $env:TEMP $AppName
$OutFile = Join-Path $TempFolder $FileName
$LogFile = Join-Path $TempFolder "launcher-log.txt"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
    param(
        [string]$Text
    )

    try {
        if (!(Test-Path $TempFolder)) {
            New-Item -ItemType Directory -Path $TempFolder | Out-Null
        }

        $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "[$Time] $Text" -Encoding UTF8
    }
    catch {
    }
}

function Set-ConsoleReady {
    try {
        $Host.UI.RawUI.WindowTitle = $AppName
    }
    catch {
    }

    try {
        [Console]::CursorVisible = $false
    }
    catch {
    }

    try {
        Clear-Host
    }
    catch {
    }
}

function Restore-Console {
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }
}

function Get-ConsoleWidthSafe {
    try {
        return [Console]::WindowWidth
    }
    catch {
        return 80
    }
}

function Write-Centered {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White"
    )

    $Width = Get-ConsoleWidthSafe

    if ($Text.Length -ge $Width) {
        Write-Host $Text -ForegroundColor $ForegroundColor
        return
    }

    $LeftPaddingCount = [math]::Floor(($Width - $Text.Length) / 2)

    if ($LeftPaddingCount -lt 0) {
        $LeftPaddingCount = 0
    }

    $LeftPadding = " " * $LeftPaddingCount

    Write-Host "$LeftPadding$Text" -ForegroundColor $ForegroundColor
}

function Write-YellowBlock {
    Write-Host -NoNewline "  " -BackgroundColor Yellow
}

function Write-EmptyBlock {
    Write-Host -NoNewline "  " -BackgroundColor Black
}

function Show-PixelLoading {
    param(
        [int]$Percent,
        [string]$StatusText
    )

    if ($Percent -lt 0) {
        $Percent = 0
    }

    if ($Percent -gt 100) {
        $Percent = 100
    }

    Clear-Host

    $TotalBlocks = 18
    $FilledBlocks = [math]::Floor(($Percent / 100) * $TotalBlocks)

    $InnerWidth = ($TotalBlocks * 2) + 2
    $TopBorder = "+" + ("-" * $InnerWidth) + "+"
    $BottomBorder = "+" + ("-" * $InnerWidth) + "+"

    $ConsoleWidth = Get-ConsoleWidthSafe
    $BarWidth = $TopBorder.Length
    $LeftPaddingCount = [math]::Floor(($ConsoleWidth - $BarWidth) / 2)

    if ($LeftPaddingCount -lt 0) {
        $LeftPaddingCount = 0
    }

    $LeftPadding = " " * $LeftPaddingCount

    Write-Host ""
    Write-Host ""
    Write-Centered "LOADING..." "Yellow"
    Write-Host ""

    Write-Host "$LeftPadding$TopBorder" -ForegroundColor White

    Write-Host -NoNewline "$LeftPadding|" -ForegroundColor White
    Write-Host -NoNewline " "

    for ($Index = 1; $Index -le $TotalBlocks; $Index++) {
        if ($Index -le $FilledBlocks) {
            Write-YellowBlock
        }
        else {
            Write-EmptyBlock
        }
    }

    Write-Host -NoNewline " "
    Write-Host "|" -ForegroundColor White

    Write-Host "$LeftPadding$BottomBorder" -ForegroundColor White
    Write-Host ""

    Write-Centered "$Percent%" "Yellow"
    Write-Host ""

    if ($null -ne $StatusText -and $StatusText.Trim() -ne "") {
        Write-Centered $StatusText "White"
    }
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

function Show-ErrorMessage {
    param(
        [string]$Message
    )

    Restore-Console

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

        [System.Windows.Forms.MessageBox]::Show(
            $Message,
            "$AppName Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        Clear-Host
        Write-Host ""
        Write-Host "$AppName Error" -ForegroundColor Red
        Write-Host ""
        Write-Host $Message -ForegroundColor White
        Write-Host ""
        Start-Sleep -Seconds 7
    }
}

function Close-ThisPowerShell {
    Restore-Console

    Start-Sleep -Milliseconds 300

    try {
        Stop-Process -Id $PID -Force
    }
    catch {
        exit
    }
}

function Test-ExeFile {
    param(
        [string]$Path
    )

    if (!(Test-Path $Path)) {
        return $false
    }

    $FileInfo = Get-Item $Path

    if ($FileInfo.Length -lt 2) {
        return $false
    }

    $FileStream = $null

    try {
        $FileStream = [System.IO.File]::OpenRead($Path)

        $Byte1 = $FileStream.ReadByte()
        $Byte2 = $FileStream.ReadByte()

        if ($Byte1 -eq 77 -and $Byte2 -eq 90) {
            return $true
        }

        return $false
    }
    catch {
        Write-Log "Test-ExeFile failed"
        Write-Log $_.Exception.Message
        return $false
    }
    finally {
        if ($null -ne $FileStream) {
            $FileStream.Close()
            $FileStream.Dispose()
        }
    }
}

function Download-FileWithPixelBar {
    param(
        [string]$Url,
        [string]$Destination
    )

    $Response = $null
    $InputStream = $null
    $OutputStream = $null

    try {
        Show-PixelLoading -Percent 0 -StatusText "Preparing download"

        $Request = [System.Net.HttpWebRequest]::Create($Url)
        $Request.Method = "GET"
        $Request.AllowAutoRedirect = $true
        $Request.UserAgent = "Mozilla/5.0 App-Loader"
        $Request.Timeout = 60000
        $Request.ReadWriteTimeout = 60000

        $Response = $Request.GetResponse()
        $TotalBytes = [int64]$Response.ContentLength

        $InputStream = $Response.GetResponseStream()
        $OutputStream = [System.IO.File]::Create($Destination)

        $Buffer = New-Object byte[] 65536
        $TotalRead = 0
        $Percent = 0
        $LastPercent = -1
        $LastDrawTime = Get-Date

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

            $Now = Get-Date
            $Elapsed = ($Now - $LastDrawTime).TotalMilliseconds

            if (($Percent -ne $LastPercent) -and ($Elapsed -ge 80)) {
                Show-PixelLoading -Percent $Percent -StatusText "Downloading loader.exe"
                $LastPercent = $Percent
                $LastDrawTime = $Now
            }
        }

        Close-Safe -Object $OutputStream
        Close-Safe -Object $InputStream
        Close-Safe -Object $Response

        Show-PixelLoading -Percent 100 -StatusText "Download complete"
        Start-Sleep -Milliseconds 500
    }
    catch {
        Close-Safe -Object $OutputStream
        Close-Safe -Object $InputStream
        Close-Safe -Object $Response

        Write-Log "Download failed"
        Write-Log $_.Exception.Message

        throw $_
    }
}

try {
    Set-ConsoleReady

    if (!(Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }

    if (Test-Path $LogFile) {
        Remove-Item -Path $LogFile -Force
    }

    Write-Log "Script started"
    Write-Log "Script version: $ScriptVersion"

    if (Test-Path $OutFile) {
        try {
            Remove-Item -Path $OutFile -Force
        }
        catch {
            Write-Log "Cannot remove old loader.exe"
            Write-Log $_.Exception.Message
        }
    }

    Show-PixelLoading -Percent 5 -StatusText "Starting"

    Download-FileWithPixelBar -Url $ExeUrl -Destination $OutFile

    if (!(Test-Path $OutFile)) {
        throw "Download completed, but loader.exe was not found."
    }

    $DownloadedFile = Get-Item $OutFile

    if ($DownloadedFile.Length -le 0) {
        throw "Downloaded loader.exe is empty."
    }

    if (!(Test-ExeFile -Path $OutFile)) {
        throw "Downloaded file is not a valid EXE. Check GitHub Release. The asset file must be named loader.exe."
    }

    try {
        Unblock-File -Path $OutFile -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Unblock-File failed"
        Write-Log $_.Exception.Message
    }

    Show-PixelLoading -Percent 100 -StatusText "Starting GUI"
    Start-Sleep -Milliseconds 500

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $OutFile
    $ProcessInfo.WorkingDirectory = $TempFolder
    $ProcessInfo.UseShellExecute = $true
    $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

    $StartedProcess = [System.Diagnostics.Process]::Start($ProcessInfo)

    if ($null -eq $StartedProcess) {
        throw "Cannot start loader.exe."
    }

    Write-Log "loader.exe started"
    Write-Log "Path: $OutFile"

    Start-Sleep -Milliseconds 1200

    Close-ThisPowerShell
}
catch {
    $ErrorMessage = $_.Exception.Message

    Write-Log "Fatal error"
    Write-Log $ErrorMessage

    Show-ErrorMessage -Message $ErrorMessage

    Close-ThisPowerShell
}
