#################################################################
# Author: Tyler Currence                                        #
# Module Dependencies: None                                     #
# Permission level: Standard User                               #
# Powershell v5                                                 #
#################################################################

#Generates password and also cross checks it with HIBP, if it is in a breach, it will force you to regenerate. You should just use SHA1....HIBP only uses that
#Creates random generated password with mandatory params of length count and alphanumeric symbol count
#Checks HaveIBeenPwned with SHA1 first 5 chars for hash match subset, then checks full hash locally against that subset for exact match
#Auto adds new password to clipboard and then clears clipboard after 30 seconds, dumps all remnants of passwords/hashes from memory
<#
    Check-HaveIBeenPwned -HashType "SHA1" -Generate
#>

#Check your own passwords against HIBP with SHA1 first 5 chars for hash match subset, then checks full hash locally against that subset for exact match, dumps all remnants of passwords/hashes from memory
<#
    Check-HaveIBeenPwned -HashType "SHA1" -Check
#>

Function New-Password  {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(14,200)]
        [int]$PasswordLength,
        [Parameter(Mandatory=$true)]
        [ValidateLength(2,30)]
        [int]$NumberOfSymbols
    )
        Add-Type -AssemblyName System.Web
        $password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength,$NumberOfSymbols)
        return $password
    }
    
    Function Check-HaveIBeenPwned {
        Param(
            [Parameter(Mandatory=$true)]
            [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")]
            [string]$HashType,
            [Parameter()]
            [switch]$Generate,
            [Parameter()]
            [switch]$Check
        )
        if ($Generate)
        {
            if ($m -ne 1)
            {
                $Password = New-Password -PasswordLength (Read-Host -Prompt "Desired password length (integer)") -NumberOfSymbols (Read-Host -Prompt "Desired amount of symbols (integer)")
            }
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $httpURL = "https://api.pwnedpasswords.com/range/"
            $m = 0
    
            $StringBuilder = New-Object System.Text.StringBuilder
            [System.Security.Cryptography.HashAlgorithm]::Create($HashType).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password)) | `
            % {
                [Void]$StringBuilder.Append($_.ToString("x2"))
            }
            $FullPWHash = $StringBuilder.ToString()
    
            $HIBPHashArray = Invoke-WebRequest -uri ($httpURL + $FullPWHash.SubString(0,5))
    
            ForEach ($hashmatch in $HIBPHashArray)
            {
                if (($hashmatch -match $FullPWHash.Substring(5)) -eq $true)
                {
                    $m = 1
                    Write-Host "`nChosen password has been pwned! Please generate a new password!" -ForegroundColor Yellow
                    $Password = New-Password -PasswordLength (Read-Host -Prompt "Desired password length (integer)") -NumberOfSymbols (Read-Host -Prompt "Desired amount of symbols (integer)")
                    Check-HaveIBeenPwned -HashType "SHA1" -Generate
                }
            }
            if ($m -eq 0)
                {
                    Write-Host "`nGenerated password has NOT been pwned!" -ForegroundColor Cyan
                    $Password | CLIP
                    Write-Host "`nGenerated password has been added to clipboard!" -ForegroundColor Cyan
                    Write-Host "`nClipboard clearing in..." -ForegroundColor Green
    
                    $i = 30
                    while ($i -gt 0) {
                        Start-Sleep -s 1; $i -= 1
                        Write-Host "`r$i" -NoNewline -ForegroundColor Cyan
                    }
    
                    echo $null | CLIP
                    Write-Host "`nClipboard has been cleared!" -ForegroundColor Green
                }
            Clear-Variable -Name Password,FullPWHash,hashmatch,HIBPHashArray
            [System.GC]::Collect()
        }
        elseif ($Check)
        {
            $Password = Read-Host -asSecureString "Enter a password to check against HIBP"
    
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $httpURL = "https://api.pwnedpasswords.com/range/"
            $m = 0
    
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    
            $StringBuilder = New-Object System.Text.StringBuilder
            [System.Security.Cryptography.HashAlgorithm]::Create($HashType).ComputeHash([System.Text.Encoding]::UTF8.GetBytes(([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)))) | `
            % {
                [Void]$StringBuilder.Append($_.ToString("x2"))
            }
            $FullPWHash = $StringBuilder.ToString()
    
            $HIBPHashArray = Invoke-WebRequest -uri ($httpURL + $FullPWHash.SubString(0,5))
    
            ForEach ($hashmatch in $HIBPHashArray)
            {
                if (($hashmatch -match $FullPWHash.Substring(5)) -eq $true)
                {
                    $m = 1
                    Write-Host "`nChosen password has been pwned! Please generate a new password!" -ForegroundColor Yellow
                }
            }
            if ($m -eq 0)
                {
                    Write-Host "`nGenerated password has NOT been pwned!" -ForegroundColor Cyan
                }
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            Clear-Variable -Name BSTR,Password,FullPWHash,hashmatch,HIBPHashArray
            [System.GC]::Collect()
        }
    }
