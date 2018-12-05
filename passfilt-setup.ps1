#######################################################################
# Author: Tyler Currence - https://github.com/tcurrence852            #
# Project: Svalinn - Stephen Hosom - https://github.com/hosom/svalinn #
# Module Dependencies: None                                           #
# Permission level: Local Admin                                       #
# Powershell v5                                                       #
#######################################################################

Function Passfilt-Setup {
<#
.SYNOPSIS
This Powershell script will install, uninstall, configure or check the status of Svalinn password filter.

.DESCRIPTION
This is pretty straight forward, and created in a very verbose fashion so you can tweak as necessary for additional functionality, such as email status reports, etc.
You NEED to run this script as a local administrator, regardless of which parameter you are specifying.

.PARAMETER -Install
This will step you through the installation process. It is required that after you complete this and reboot, you then run this script again with the "-Configure" option.

.PARAMETER -Remove
This will remove svalinn reg keys and unload the .dll module from your system.

.PARAMETER -Configure
This is required to run after you have completed the install step, or simply want to reconfigure your current svalinn instance.

.PARAMETER -Status
Utilize this option at any time to check the existence of all required configuration reg keys, their values, and .dll module load status.

.EXAMPLE
Open a powershell console as a local administrator execute script as follows (you likely will need to dot source this as seen below)

Example 1 without execution policy workarounds: 
. .\passfilt-setup.ps1; Passfilt-Setup -Status

Example 2 with execution policy workarounds: 
. .\passfilt-setup.ps1 -ep bypass; Passfilt-Setup -Status

.NOTES
Powershell V5 is required. If you are running a lower version, it may or may not work, but is definitely untested at this time.
#>
    Param(
        [Parameter()]
        [switch]$Install,
        [Parameter()]
        [switch]$Remove,
        [Parameter()]
        [switch]$Configure,
        [Parameter()]
        [switch]$Status
    )
    If ($Install -eq $true)
    {
        try
        {
            Write-Host "`nInstallation is starting...`n" -ForegroundColor Cyan

            $YesOrNo = Read-Host -Prompt "You are about to install Svalinn password filter, please confirm (Y/N)"

            If ("y", "Y" -contains $YesOrNo){

                $DLLPath = Read-Host -Prompt "Enter directory path containing compiled svalinn.dll (ex: c:\stuff\things\)"

                try
                {
                    Move-Item -Path ($DLLPath + "svalinn.dll") -Destination ($env:SystemRoot + "\System32\") -Force -ErrorAction Stop
                }
                catch
                {
                    Write-Host "`nCannot copy svalinn.dll to system32, check permissions and re-run!" -ForegroundColor Yellow
                    break
                }
                
                Write-Host "Svalinn DLL has copied to {root}\System32\...`n" -ForegroundColor Cyan

                $LSAReg = ((Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name "Notification Packages") | Out-String)

                $LSARegNew = $LSAReg + "svalinn"

                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name "Notification Packages" -Value $LSARegNew -Type MultiString –Force -ErrorAction Stop

                Write-Host "Svalinn added to LSA registry key...`n" -ForegroundColor Cyan

                Restart-Computer -Force -InformationAction "System will now reboot!" -Confirm:$true
            }
            else{
                Write-Host "Installation cancelled!`n"
            }  
        }
        catch
        {
            Write-Host "`nAn error has occurred during installation, please re-run!" -ForegroundColor Yellow
            break
        }
        
    }
    If ($Remove -eq $true)
    {
        try
        {
            Write-Host "`nPassfilt removal is starting...`n" -ForegroundColor Cyan

            $YesOr = Read-Host -Prompt "You are about to remove Svalinn password filter, please confirm (Y/N)"

            If ("y", "Y" -contains $YesOr){

                $LSAReg = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name "Notification Packages" -ErrorAction Stop

                $LSARegNew = $LSAReg.Replace("svalinn","")

                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name "Notification Packages" -Value $LSARegNew -Type MultiString –Force -ErrorAction Stop

                Write-Host "Svalinn removed from LSA registry key...`n" -ForegroundColor Cyan

                Restart-Computer -Force -ErrorAction Stop -InformationAction "Uninstall complete, system will now reboot!" -Confirm:$true
            }
            else{
                Write-Host "Removal cancelled!`n"
                break
            }
        }catch{
            Write-Host "`nAn error has occurred during passfilt removal, please re-run!" -ForegroundColor Yellow
            break
        }
    }
    If ($Configure -eq $true)
    {
        try
        {
            Write-Host "`nConfiguration is starting...`n" -ForegroundColor Cyan

            $YesOrNo = Read-Host -Prompt "You are about to configure Svalinn password filter, please confirm (Y/N)"

            If ("y", "Y" -contains $YesOrNo){

                Test-Path -Path "HKLM:\SOFTWARE\passfilt" -ErrorAction Stop -InformationAction SilentlyContinue

                $ServerReg = Read-Host -Prompt "Enter fully qualified passfilt server name, or IP address"
                If ($ServerReg){
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Server" -Value $ServerReg -PropertyType REG_SZ –Force -ErrorAction Stop
                }

                $PortReg = Read-Host -Prompt "Enter port number to use for passfilt server queries"
                If ($PortReg){
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Port" -Value $PortReg -PropertyType DWord –Force -ErrorAction Stop
                }

                $EnableTLSReg = Read-Host -Prompt "Enable TLS? Y/N (Choosing 'Y' is STRONGLY recommended)"
                If ("", " ", $null, "y", "Y" -contains $EnableTLSReg){
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Enable TLS" -Value "1" -PropertyType DWord –Force -ErrorAction Stop
                }else{
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Enable TLS" -Value "0" -PropertyType DWord –Force -ErrorAction Stop
                }

                $DisableTLSReg = Read-Host -Prompt "Disable TLS Validation? Y/N (Choosing 'Y' is STRONGLY DISCOURAGED)"
                If ("", " ", $null, "n", "N" -contains $DisableTLSReg){
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Disable TLS Validation" -Value "0" -PropertyType DWord –Force -ErrorAction Stop
                }else{
                    New-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -Name "Disable TLS Validation" -Value "1" -PropertyType DWord –Force -ErrorAction Stop
                }

                Write-Host "Configuration registry keys are entered...`n" -ForegroundColor Cyan

                Write-Host "Configuration complete, a reboot is recommended! Check svalinn status with option '-Status'`n" -ForegroundColor Cyan
            }
            else
            {
                Write-Host "Configuration cancelled!`n"
                break
            }
        }
        catch
        {
            Write-Host "`nAn error has occurred during configuration, double check svalinn status with option '-Status'" -ForegroundColor Yellow
            break
        }
    }
    If ($Status -eq $true)
    {
        $StatusTable = @()

        Write-Host "`nGathering svalinn status report...please wait one moment`n" -ForegroundColor Cyan
        $ErrorActionPreference = 'ignore'
        $ModLoad = gwmi -namespace root\cimv2 -class CIM_ProcessExecutable | % {[wmi]"$($_.Antecedent)" | select * } | ?{$_.FileName -eq "svalinn"} | select Name
        $ErrorActionPreference = 'continue'

        $ConfigRegPath = Test-Path -Path "HKLM:\SOFTWARE\passfilt" -ErrorAction SilentlyContinue
        $ConfigRegKeys = Get-ItemProperty -Path "HKLM:\SOFTWARE\passfilt" -ErrorAction SilentlyContinue

        $StatusObject = New-Object -TypeName psobject -Property @{
            DLLModuleStatus = if ($ModLoad){($ModLoad + " module loaded")}else{"Svalinn DLL module not loaded"}
            ConfigRegPath =  if ($ConfigRegPath -eq $false){"Config registry path does not exist"}else{$ConfigRegPath}
            ConfigRegKeys =  if (!$ConfigRegKeys){"Config registry keys do not exist"}else{$ConfigRegKeys}
        }    
        $StatusTable += $StatusObject

        Write-Host "Svalinn Status:" -ForegroundColor Cyan
        $StatusTable | select * | fl    
    }
    ElseIf (-not ($Install.IsPresent -or $Remove.IsPresent -or $Configure.IsPresent -or $Status.IsPresent))
    {
        Write-Host "`nYou need to specify a parameter (-Install, -Remove, -Configure, -Status)"
        break
    }
}