$ExeUrl = "https://github.com/Wxyuz/App-Loader/releases/latest/download/loader.exe"
$FileName = "loader.exe"
$AppName = "App-Loader"

$TempFolder = Join-Path $env:TEMP $AppName
$OutFile = Join-Path $TempFolder $FileName

Clear-Host

Write-Host ""
Write-Host "======================================"
Write-Host "              App-Loader"
Write-Host "======================================"
Write-Host ""

if (!(Test-Path $TempFolder)) {
    New-Item -ItemType Directory -Path $TempFolder | Out-Null
}

if (Test-Path $OutFile) {
    Remove-Item $OutFile -Force
}

try {
    Write-Progress -Activity "App-Loader" -Status "กำลังเชื่อมต่อเซิร์ฟเวอร์..." -PercentComplete 5

    $WebClient = New-Object System.Net.WebClient

    $Global:DownloadComplete = $false
    $Global:DownloadFailed = $false

    Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -Action {
        $percent = $EventArgs.ProgressPercentage

        if ($percent -lt 0) {
            $percent = 0
        }

        if ($percent -gt 100) {
            $percent = 100
        }

        Write-Progress `
            -Activity "App-Loader" `
            -Status "กำลังดาวน์โหลด loader.exe... $percent%" `
            -PercentComplete $percent
    } | Out-Null

    Register-ObjectEvent -InputObject $WebClient -EventName DownloadFileCompleted -Action {
        if ($EventArgs.Error) {
            $Global:DownloadFailed = $true
        }

        $Global:DownloadComplete = $true
    } | Out-Null

    $DownloadUri = New-Object System.Uri($ExeUrl)
    $WebClient.DownloadFileAsync($DownloadUri, $OutFile)

    while (-not $Global:DownloadComplete) {
        Start-Sleep -Milliseconds 150
    }

    Write-Progress -Activity "App-Loader" -Completed

    if ($Global:DownloadFailed) {
        throw "ดาวน์โหลดไม่สำเร็จ"
    }
}
catch {
    Write-Progress -Activity "App-Loader" -Completed
    Clear-Host
    Write-Host ""
    Write-Host "ดาวน์โหลดไม่สำเร็จ"
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Pause
    exit
}

if (!(Test-Path $OutFile)) {
    Clear-Host
    Write-Host ""
    Write-Host "ไม่พบไฟล์ loader.exe หลังดาวน์โหลด"
    Write-Host ""
    Pause
    exit
}

Clear-Host

Write-Host ""
Write-Host "======================================"
Write-Host "              App-Loader"
Write-Host "======================================"
Write-Host ""
Write-Host "ดาวน์โหลดเสร็จแล้ว"
Write-Host ""
Write-Host "ไฟล์:"
Write-Host $OutFile
Write-Host ""

$RunConfirm = Read-Host "ต้องการเปิด loader.exe ตอนนี้ไหม? พิมพ์ Y แล้วกด Enter"

if ($RunConfirm -eq "Y" -or $RunConfirm -eq "y") {
    Clear-Host
    Write-Host ""
    Write-Host "กำลังเปิด loader.exe..."
    Start-Sleep -Milliseconds 500

    try {
        Start-Process -FilePath $OutFile
        Clear-Host
        Write-Host ""
        Write-Host "เปิดโปรแกรมแล้ว"
        Write-Host ""
    }
    catch {
        Clear-Host
        Write-Host ""
        Write-Host "เปิดโปรแกรมไม่สำเร็จ"
        Write-Host ""
        Write-Host $_.Exception.Message
        Write-Host ""
        Pause
        exit
    }
}
else {
    Clear-Host
    Write-Host ""
    Write-Host "ยกเลิกการเปิดโปรแกรม"
    Write-Host ""
    Write-Host "ไฟล์ถูกดาวน์โหลดไว้ที่:"
    Write-Host $OutFile
    Write-Host ""
}
