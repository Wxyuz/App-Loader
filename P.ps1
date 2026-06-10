$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$AppName = "App-Loader Network Diagnostic"
$GitHubHost = "github.com"
$RawGitHubHost = "raw.githubusercontent.com"
$KeyAuthHost = "keyauth.win"

$GitHubUrl = "https://github.com"
$RawScriptUrl = "https://raw.githubusercontent.com/Wxyuz/App-Loader/main/P.ps1"
$ReleaseExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$KeyAuthUrl = "https://keyauth.win/api/1.3/"

$ReportFolder = Join-Path $env:TEMP "App-Loader-Diagnostic"
$ReportFile = Join-Path $ReportFolder "diagnostic-report.txt"
$TempDownloadFile = Join-Path $ReportFolder "loader-test.exe"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Initialize-Report {
    if (!(Test-Path $ReportFolder)) {
        New-Item -ItemType Directory -Path $ReportFolder | Out-Null
    }

    if (Test-Path $ReportFile) {
        Remove-Item -Path $ReportFile -Force
    }

    if (Test-Path $TempDownloadFile) {
        Remove-Item -Path $TempDownloadFile -Force
    }

    Add-Report "=============================================="
    Add-Report " App-Loader Network Diagnostic"
    Add-Report "=============================================="
    Add-Report "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Report "Computer: $env:COMPUTERNAME"
    Add-Report "User: $env:USERNAME"
    Add-Report "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
    Add-Report "PowerShell: $($PSVersionTable.PSVersion)"
    Add-Report "=============================================="
    Add-Report ""
}

function Add-Report {
    param(
        [string]$Text
    )

    Write-Host $Text

    try {
        Add-Content -Path $ReportFile -Value $Text -Encoding UTF8
    }
    catch {
    }
}

function Add-Section {
    param(
        [string]$Title
    )

    Add-Report ""
    Add-Report "----------------------------------------------"
    Add-Report $Title
    Add-Report "----------------------------------------------"
}

function Test-DnsResolve {
    param(
        [string]$HostName
    )

    Add-Report "DNS Test: $HostName"

    try {
        $Result = Resolve-DnsName -Name $HostName -ErrorAction Stop

        foreach ($Item in $Result) {
            if ($Item.IPAddress) {
                Add-Report "  OK: $($Item.IPAddress)"
            }
        }

        return $true
    }
    catch {
        Add-Report "  FAIL: DNS resolve failed"
        Add-Report "  Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-TcpConnect {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutMilliseconds = 6000
    )

    Add-Report "TCP Test: $HostName`:$Port"

    $Client = $null

    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $AsyncResult = $Client.BeginConnect($HostName, $Port, $null, $null)
        $Success = $AsyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)

        if ($Success -ne $true) {
            Add-Report "  FAIL: Timeout"
            try {
                $Client.Close()
            }
            catch {
            }

            return $false
        }

        $Client.EndConnect($AsyncResult)
        Add-Report "  OK: Connected"

        try {
            $Client.Close()
        }
        catch {
        }

        return $true
    }
    catch {
        Add-Report "  FAIL: Cannot connect"
        Add-Report "  Error: $($_.Exception.Message)"

        try {
            if ($null -ne $Client) {
                $Client.Close()
            }
        }
        catch {
        }

        return $false
    }
}

function Test-WebRequest {
    param(
        [string]$Url,
        [string]$Name,
        [int]$TimeoutSeconds = 12
    )

    Add-Report "HTTPS Test: $Name"
    Add-Report "URL: $Url"

    try {
        $Response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec $TimeoutSeconds -ErrorAction Stop

        Add-Report "  OK: HTTP $($Response.StatusCode)"
        Add-Report "  Status: $($Response.StatusDescription)"

        return $true
    }
    catch {
        Add-Report "  FAIL: HTTPS request failed"
        Add-Report "  Error: $($_.Exception.Message)"

        return $false
    }
}

function Test-ProxySettings {
    Add-Section "Proxy Settings"

    try {
        $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $TestUri = New-Object System.Uri("https://github.com")
        $ProxyUri = $Proxy.GetProxy($TestUri)

        if ($ProxyUri.AbsoluteUri -eq $TestUri.AbsoluteUri) {
            Add-Report "System proxy: Not using proxy"
        }
        else {
            Add-Report "System proxy: $($ProxyUri.AbsoluteUri)"
        }
    }
    catch {
        Add-Report "Proxy check failed: $($_.Exception.Message)"
    }

    try {
        $WinHttpProxy = netsh winhttp show proxy
        Add-Report ""
        Add-Report "WinHTTP Proxy:"
        foreach ($Line in $WinHttpProxy) {
            Add-Report "  $Line"
        }
    }
    catch {
        Add-Report "WinHTTP proxy check failed: $($_.Exception.Message)"
    }
}

function Test-FirewallProfiles {
    Add-Section "Windows Firewall Profiles"

    try {
        $Profiles = Get-NetFirewallProfile

        foreach ($Profile in $Profiles) {
            Add-Report "Profile: $($Profile.Name)"
            Add-Report "  Enabled: $($Profile.Enabled)"
            Add-Report "  DefaultInboundAction: $($Profile.DefaultInboundAction)"
            Add-Report "  DefaultOutboundAction: $($Profile.DefaultOutboundAction)"
        }
    }
    catch {
        Add-Report "Firewall profile check failed: $($_.Exception.Message)"
    }
}

function Test-DownloadedExeHeader {
    Add-Section "GitHub Release EXE Download Test"

    Add-Report "Download URL:"
    Add-Report $ReleaseExeUrl
    Add-Report ""

    try {
        Invoke-WebRequest -Uri $ReleaseExeUrl -OutFile $TempDownloadFile -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop

        if (!(Test-Path $TempDownloadFile)) {
            Add-Report "FAIL: File was not downloaded"
            return $false
        }

        $FileInfo = Get-Item $TempDownloadFile
        Add-Report "Downloaded size: $($FileInfo.Length) bytes"

        if ($FileInfo.Length -lt 2) {
            Add-Report "FAIL: File is too small"
            return $false
        }

        $FileStream = $null

        try {
            $FileStream = [System.IO.File]::OpenRead($TempDownloadFile)
            $Byte1 = $FileStream.ReadByte()
            $Byte2 = $FileStream.ReadByte()

            Add-Report "First bytes: $Byte1 $Byte2"

            if ($Byte1 -eq 77 -and $Byte2 -eq 90) {
                Add-Report "OK: File header is MZ, this is a Windows EXE"
                return $true
            }
            else {
                Add-Report "FAIL: File is not EXE. It may be HTML/404/login page instead of loader.exe"
                return $false
            }
        }
        finally {
            if ($null -ne $FileStream) {
                $FileStream.Close()
                $FileStream.Dispose()
            }
        }
    }
    catch {
        Add-Report "FAIL: Download test failed"
        Add-Report "Error: $($_.Exception.Message)"
        return $false
    }
}

function Show-FinalAdvice {
    param(
        [bool]$GitHubDnsOK,
        [bool]$RawDnsOK,
        [bool]$KeyAuthDnsOK,
        [bool]$GitHubTcpOK,
        [bool]$RawTcpOK,
        [bool]$KeyAuthTcpOK,
        [bool]$GitHubHttpsOK,
        [bool]$RawHttpsOK,
        [bool]$KeyAuthHttpsOK,
        [bool]$ExeOK
    )

    Add-Section "Result Summary"

    Add-Report "GitHub DNS: $GitHubDnsOK"
    Add-Report "Raw GitHub DNS: $RawDnsOK"
    Add-Report "KeyAuth DNS: $KeyAuthDnsOK"
    Add-Report "GitHub TCP 443: $GitHubTcpOK"
    Add-Report "Raw GitHub TCP 443: $RawTcpOK"
    Add-Report "KeyAuth TCP 443: $KeyAuthTcpOK"
    Add-Report "GitHub HTTPS: $GitHubHttpsOK"
    Add-Report "Raw Script HTTPS: $RawHttpsOK"
    Add-Report "KeyAuth HTTPS: $KeyAuthHttpsOK"
    Add-Report "Release loader.exe valid: $ExeOK"

    Add-Report ""
    Add-Report "Fix Guide:"

    if ($GitHubDnsOK -ne $true -or $RawDnsOK -ne $true -or $KeyAuthDnsOK -ne $true) {
        Add-Report "1. DNS มีปัญหา: ลองเปลี่ยน DNS เป็น 1.1.1.1 หรือ 8.8.8.8 แล้วรันใหม่"
    }

    if ($GitHubTcpOK -ne $true -or $RawTcpOK -ne $true -or $KeyAuthTcpOK -ne $true) {
        Add-Report "2. TCP 443 ถูกบล็อก: เช็ก Firewall, Antivirus, VPN, Proxy, เน็ตโรงเรียน/ที่ทำงาน"
    }

    if ($KeyAuthHttpsOK -ne $true) {
        Add-Report "3. KeyAuth HTTPS ใช้ไม่ได้บนเครื่องนี้: โปรแกรม GUI จะมีโอกาสขึ้น WinError 10061/Network Error"
        Add-Report "   ต้องแก้ที่ network หรือแก้ source ของ loader.exe ให้ใช้ endpoint/library KeyAuth ปัจจุบัน"
    }

    if ($ExeOK -ne $true) {
        Add-Report "4. loader.exe ใน Release ไม่ถูกต้อง: ตรวจว่าไฟล์ asset ชื่อ loader.exe ตรงตัว และเป็น EXE จริง"
    }

    if (
        $GitHubDnsOK -eq $true -and
        $RawDnsOK -eq $true -and
        $KeyAuthDnsOK -eq $true -and
        $GitHubTcpOK -eq $true -and
        $RawTcpOK -eq $true -and
        $KeyAuthTcpOK -eq $true -and
        $GitHubHttpsOK -eq $true -and
        $RawHttpsOK -eq $true -and
        $KeyAuthHttpsOK -eq $true -and
        $ExeOK -eq $true
    ) {
        Add-Report "ทุกอย่างด้าน network ผ่าน ถ้า GUI ยังขึ้น KeyAuth Error ให้แก้ที่ source ของ loader.exe แล้ว build ใหม่"
        Add-Report "เช็ก name / ownerid / version / endpoint / SDK KeyAuth / TLS / Runtime ให้ถูกต้อง"
    }

    Add-Report ""
    Add-Report "Report saved to:"
    Add-Report $ReportFile
}

try {
    Clear-Host
    $Host.UI.RawUI.WindowTitle = $AppName
}
catch {
}

Initialize-Report

Add-Section "DNS"

$GitHubDnsOK = Test-DnsResolve -HostName $GitHubHost
$RawDnsOK = Test-DnsResolve -HostName $RawGitHubHost
$KeyAuthDnsOK = Test-DnsResolve -HostName $KeyAuthHost

Add-Section "TCP 443"

$GitHubTcpOK = Test-TcpConnect -HostName $GitHubHost -Port 443 -TimeoutMilliseconds 6000
$RawTcpOK = Test-TcpConnect -HostName $RawGitHubHost -Port 443 -TimeoutMilliseconds 6000
$KeyAuthTcpOK = Test-TcpConnect -HostName $KeyAuthHost -Port 443 -TimeoutMilliseconds 6000

Add-Section "HTTPS"

$GitHubHttpsOK = Test-WebRequest -Url $GitHubUrl -Name "GitHub"
$RawHttpsOK = Test-WebRequest -Url $RawScriptUrl -Name "Raw GitHub Script"
$KeyAuthHttpsOK = Test-WebRequest -Url $KeyAuthUrl -Name "KeyAuth API 1.3"

Test-ProxySettings
Test-FirewallProfiles

$ExeOK = Test-DownloadedExeHeader

Show-FinalAdvice `
    -GitHubDnsOK $GitHubDnsOK `
    -RawDnsOK $RawDnsOK `
    -KeyAuthDnsOK $KeyAuthDnsOK `
    -GitHubTcpOK $GitHubTcpOK `
    -RawTcpOK $RawTcpOK `
    -KeyAuthTcpOK $KeyAuthTcpOK `
    -GitHubHttpsOK $GitHubHttpsOK `
    -RawHttpsOK $RawHttpsOK `
    -KeyAuthHttpsOK $KeyAuthHttpsOK `
    -ExeOK $ExeOK

Write-Host ""
Write-Host "กด Enter เพื่อปิดหน้าต่างนี้..."
Read-Host | Out-Null
