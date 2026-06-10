$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$AppName = "App-Loader"
$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"

$TempFolder = Join-Path $env:TEMP $AppName
$OutFile = Join-Path $TempFolder $FileName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Set-SafeConsole {
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
        $RawUI = $Host.UI.RawUI
        $WindowSize = $RawUI.WindowSize

        if ($WindowSize.Width -lt 80) {
            $WindowSize.Width = 80
        }

        if ($WindowSize.Height -lt 22) {
            $WindowSize.Height = 22
        }

        $RawUI.WindowSize = $WindowSize
    }
    catch {
    }

    try {
        $RawUI = $Host.UI.RawUI
        $BufferSize = $RawUI.BufferSize

        if ($BufferSize.Width -lt 80) {
            $BufferSize.Width = 80
        }

        if ($BufferSize.Height -lt 300) {
            $BufferSize.Height = 300
        }

        $RawUI.BufferSize = $BufferSize
    }
    catch {
    }
}

function Reset-SafeConsole {
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }
}

function Write-CenterText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    try {
        $Width = [Console]::WindowWidth
    }
    catch {
        $Width = 80
    }

    if ($Text.Length -ge $Width) {
        Write-Host $Text -ForegroundColor $Color
        return
    }

    $Left = [math]::Floor(($Width - $Text.Length) / 2)

    if ($Left -lt 0) {
        $Left = 0
    }

    $Padding = " " * $Left

    Write-Host "$Padding$Text" -ForegroundColor $Color
}

function Write-PixelBlock {
    param(
        [bool]$Filled
    )

    if ($Filled) {
        Write-Host -NoNewline "  " -BackgroundColor Yellow
    }
    else {
        Write-Host -NoNewline "  " -BackgroundColor Black
    }
}

function Show-PixelLoadingBar {
    param(
        [int]$Percent
    )

    if ($Percent -lt 0) {
        $Percent = 0
    }

    if ($Percent -gt 100) {
        $Percent = 100
    }

    Clear-Host

    Write-Host ""
    Write-Host ""
    Write-CenterText "LOADING..." "Yellow"
    Write-Host ""

    $TotalBlocks = 24
    $FilledBlocks = [math]::Floor(($Percent / 100) * $TotalBlocks)

    $BarInnerWidth = $TotalBlocks * 2
    $TopBorder = "+" + ("-" * ($BarInnerWidth + 2)) + "+"
    $BottomBorder = "+" + ("-" * ($BarInnerWidth + 2)) + "+"

    try {
        $ConsoleWidth = [Console]::WindowWidth
    }
    catch {
        $ConsoleWidth = 80
    }

    $LeftPaddingCount = [math]::Floor(($ConsoleWidth - $TopBorder.Length) / 2)

    if ($LeftPaddingCount -lt 0) {
        $LeftPaddingCount = 0
    }

    $LeftPadding = " " * $LeftPaddingCount

    Write-Host "$LeftPadding$TopBorder" -ForegroundColor White

    Write-Host -NoNewline "$LeftPadding|" -ForegroundColor White
    Write-Host -NoNewline " "

    for ($Index = 1; $Index -le $TotalBlocks; $Index++) {
        if ($Index -le $FilledBlocks) {
            Write-PixelBlock -Filled $true
        }
        else {
            Write-PixelBlock -Filled $false
        }
    }

    Write-Host -NoNewline " "
    Write-Host "|" -ForegroundColor White

    Write-Host "$LeftPadding$BottomBorder" -ForegroundColor White
    Write-Host ""

    $PercentText = "$Percent%"

    Write-CenterText $PercentText "Yellow"
    Write-Host ""
}

function Show-ErrorBox {
    param(
        [string]$Message
    )

    try {
        Reset-SafeConsole
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
        Start-Sleep -Seconds 6
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

function Download-FileWithPixelProgress {
    param(
        [string]$Url,
        [string]$Destination
    )

    $Response = $null
    $InputStream = $null
    $OutputStream = $null

    try {
        Show-PixelLoadingBar -Percent 0

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
            $MillisecondsPassed = ($Now - $LastDrawTime).TotalMilliseconds

            if (($Percent -ne $LastPercent) -and ($MillisecondsPassed -ge 60)) {
                Show-PixelLoadingBar -Percent $Percent
                $LastPercent = $Percent
                $LastDrawTime = $Now
            }
        }

        Close-Safe -Object $OutputStream
        Close-Safe -Object $InputStream
        Close-Safe -Object $Response

        Show-PixelLoadingBar -Percent 100
        Start-Sleep -Milliseconds 500
    }
    catch {
        Close-Safe -Object $OutputStream
        Close-Safe -Object $InputStream
        Close-Safe -Object $Response

        throw $_
    }
}

try {
    Set-SafeConsole
    Clear-Host

    if (!(Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }

    if (Test-Path $OutFile) {
        Remove-Item -Path $OutFile -Force
    }

    Download-FileWithPixelProgress -Url $ExeUrl -Destination $OutFile

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
    }

    Clear-Host

    Write-Host ""
    Write-Host ""
    Write-CenterText "LOADING COMPLETE" "Yellow"
    Write-Host ""
    Show-PixelLoadingBar -Percent 100

    Reset-SafeConsole

    Write-Host ""
    Write-CenterText "File ready: $OutFile" "White"
    Write-Host ""

    $RunConfirm = Read-Host "Type Y and press Enter to open loader.exe"

    if ($RunConfirm -eq "Y" -or $RunConfirm -eq "y") {
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = $OutFile
        $ProcessInfo.WorkingDirectory = $TempFolder
        $ProcessInfo.UseShellExecute = $true
        $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

        $StartedProcess = [System.Diagnostics.Process]::Start($ProcessInfo)

        if ($null -eq $StartedProcess) {
            throw "Cannot start loader.exe."
        }

        Start-Sleep -Milliseconds 800
    }
    else {
        Clear-Host
        Write-Host ""
        Write-Host "Cancelled." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "File saved to:" -ForegroundColor White
        Write-Host $OutFile -ForegroundColor White
        Write-Host ""
        Start-Sleep -Seconds 4
    }

    exit
}
catch {
    Reset-SafeConsole

    $ErrorMessage = $_.Exception.Message

    Show-ErrorBox -Message $ErrorMessage

    exit
}
