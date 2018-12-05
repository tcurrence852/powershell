#################################################################
# Author: Tyler Currence                                        #
# Module Dependencies: None                                     #
# Permission level: Standard User                               #
# Powershell v4                                                 #
#################################################################
#Input expected hash of a file, choose hash algorithm, compares expected hash to the actual
#calculated file hash
Function Compare-HashValue  {
    Param(
        [Parameter(Mandatory=$true)]    
        [string]$ExpectedHash,
        [Parameter(Mandatory=$true)] 
        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")]   
        [string]$HashAlgorithm,
        [Parameter(Mandatory=$true)]    
        [string]$PathToFileForCompare
    )
        $gethash = Get-FileHash -Path $PathToFileForCompare -Algorithm $HashAlgorithm
        
        if ($gethash.hash -ne $ExpectedHash)
        {
            Write-Host "`nDownloaded file has different hash than expected! Make sure you used the correct algorithm" -ForegroundColor Red
            Write-Host ($gethash.hash.ToString() + "`n") -ForegroundColor Yellow
        } elseif ($gethash.hash -eq $ExpectedHash) 
        {
            Write-Host "`nDownloaded file hash matches expected value!`n" -ForegroundColor Cyan
        }
    }