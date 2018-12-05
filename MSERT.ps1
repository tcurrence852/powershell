#################################################################
# Author: Tyler Currence                                        #
# Module Dependencies: None                                     #
# Permission level: Local Admin - network access                #
# Powershell v2                                                 #
#################################################################

#Defaults
$MSERT64 = "https://definitionupdates.microsoft.com/download/definitionupdates/safetyscanner/amd64/msert.exe"
$MSERT32 = "https://definitionupdates.microsoft.com/download/definitionupdates/safetyscanner/x86/msert.exe"
$Exe64Name = "msertx64.exe"
$Exe32Name = "msertx86.exe"
$DefaultPath = "C:\MSERT\" #path for scanner exe and log

#Begin OS architecture detection + download correct MSERT version
$OSArch = gwmi Win32_OperatingSystem | select -ExpandProperty OSArchitecture
$client = New-Object System.Net.WebClient
New-Item -ItemType "directory" -Path $DefaultPath -Force -InformationAction SilentlyContinue

try {
    if ($OSArch -eq "64-bit") {
        $client.DownloadFile( $MSERT64, ($DefaultPath + $Exe64Name)) | Out-Null
        $ExeName = $Exe64Name
    }
    elseif ($OSArch -eq "32-bit") {
        $client.DownloadFile( $MSERT32, ($DefaultPath + $Exe32Name)) | Out-Null
        $ExeName = $Exe32Name
    }
}
catch {
    Write-Host "$($_.Exception.InnerExceptionMessage)`n"
    Write-Host "Download has failed, verify download URL and network connectivity!"
    break
}

Write-Host "`nAvailable command line options (leave blank for none)" -ForegroundColor Yellow
Write-Host "`n/Q - Quiet Mode" -ForegroundColor Cyan
Write-Host "`n/? - Display usage info" -ForegroundColor Cyan
Write-Host "`n/N - Detection only mode" -ForegroundColor Cyan
Write-Host "`n/F - Force full scan" -ForegroundColor Cyan
Write-Host "`n/F:Y - Force full scan and auto clean/remove infected files" -ForegroundColor Cyan
Write-Host "`n/H - Detect severe threats only" -ForegroundColor Cyan
Write-Host "`nNone - This runs in full GUI, required for folder specific scans`n" -ForegroundColor Cyan

$ExecParams = Read-Host -Prompt "Enter parameters (separated by a space for multiple selections)"

try {  
    Write-Host "`nMSERT will now execute, do not exit this window, this may take a few hours depending on parameter inputs...`n" -ForegroundColor Yellow
    if (($ExecParams -match "/") -eq $true) {
        Start-Process -FilePath ($DefaultPath + $ExeName) -ArgumentList $ExecParams -Wait -ErrorAction Stop
    }
    else {
        Start-Process -FilePath ($DefaultPath + $ExeName) -Wait -ErrorAction Stop
    }
    sleep -Seconds 5
    If (($DefaultPath + $ExeName)) {
        Remove-Item -Path ($DefaultPath + $ExeName) -Force
    }
    Move-Item -Path $("$env:SystemRoot\debug\msert.log") -Destination $DefaultPath -Force
    Write-Host ($env:COMPUTERNAME + " MSERT scan is complete, results log available in " + ($DefaultPath + "msert.log")) -ForegroundColor Yellow
}
catch {
    Write-Host "$($_.Exception.Message)`n"
    Write-Host "MSERT process has encountered the error above and will terminate"
}