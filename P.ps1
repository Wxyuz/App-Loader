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

function Show-ErrorBox {
    param(
        [string]$Message
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show(
            $Message,
            "App-Loader Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        Clear-Host
        Write-Host ""
        Write-Host "App-Loader Error"
        Write-Host ""
        Write-Host $Message
        Write-Host ""
        Start-Sleep -Seconds 6
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
        return $false
    }
    finally {
        if ($null -ne $FileStream) {
            $FileStream.Close()
            $FileStream.Dispose()
        }
    }
}

function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$Destination
    )

    $Response = $null
    $InputStream = $null
    $OutputStream = $null

    try {
        Show-ProgressBar -Percent 0

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
        Start-Sleep -Milliseconds 400
    }
    catch {
        Close-Safe -Object $OutputStream
        Close-Safe -Object $InputStream
        Close-Safe -Object $Response

        throw $_
    }
}

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

    Download-FileWithProgress -Url $ExeUrl -Destination $OutFile

    if (!(Test-Path $OutFile)) {
        throw "Download completed, but loader.exe was not found."
    }

    $DownloadedFile = Get-Item $OutFile

    if ($DownloadedFile.Length -le 0) {
        throw "Downloaded loader.exe is empty."
    }

    if (!(Test-ExeFile -Path $OutFile)) {
        throw "Downloaded file is not a valid EXE. Check GitHub Release. The file name must be loader.exe and the Release asset must exist."
    }

    try {
        Unblock-File -Path $OutFile -ErrorAction SilentlyContinue
    }
    catch {
    }

    Clear-Host
    Show-ProgressBar -Percent 100
    Start-Sleep -Milliseconds 300

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $OutFile
    $ProcessInfo.WorkingDirectory = $TempFolder
    $ProcessInfo.UseShellExecute = $true
    $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

    $StartedProcess = [System.Diagnostics.Process]::Start($ProcessInfo)

    if ($null -eq $StartedProcess) {
        throw "Cannot start loader.exe."
    }

    Start-Sleep -Milliseconds 1200

    if ($StartedProcess.HasExited) {
        $ExitCode = $StartedProcess.ExitCode

        throw "loader.exe started but closed immediately. Exit code: $ExitCode. This usually means missing .NET Desktop Runtime, missing VC++ Runtime, or the EXE was built as Console App instead of GUI App."
    }

    Close-ThisPowerShell
}
catch {
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }

    $ErrorMessage = $_.Exception.Message

    Show-ErrorBox -Message $ErrorMessage

    Close-ThisPowerShell
}
