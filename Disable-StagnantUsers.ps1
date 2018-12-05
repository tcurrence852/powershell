$DomainControllers = "list each of your DCs, comma delimited"
$outputrecipients = "<emailaddress>>"
$outputsender = "<emailaddress>"
$ExportFileName = "D:\Powershell\Output\DisabledAccounts\StagnantAccounts_$((Get-Date).ToString('MM-dd-yyyy_hh-mm-ss')).csv"
$stagnantusers = @()

$currentUTC = [DateTime]::Now.Subtract([TimeSpan]::FromDays(91)).ToFileTime()

    $userlist = get-aduser -Filter * -properties * | where {($_.Enabled -eq "True") -and ($_.lastLogonTimeStamp -ne $null)} | `
    select Name,SamAccountName,Description,DistinguishedName,Manager
    foreach ($value in $userlist)
    {
        $latestdate = @()
        foreach ($DC in $DomainControllers)
        {
            $latestdate += New-Object -TypeName psobject -Property @{
                RecentLogon = (get-aduser -Identity $value.SamAccountName -Properties * -Server $DC | select -ExpandProperty lastLogonTimeStamp)
            }
        }

        $DClastdate = $latestdate | Sort-Object {$_.RecentLogon -as [uint64]} | select -Last 1
        $UserManager = get-aduser -Identity $value.Manager -properties * | select DisplayName,EmailAddress
        If ($DClastdate.RecentLogon -gt $currentUTC)
        {
            $Date = (get-date).ToString()
            $Description = ('Disabled on ' + $Date + ' due to 90 days of inactivity. ' + $value.Description)
            $value | select -expandproperty SamAccountName | Set-ADUser -Description $Description
            $value | select -expandproperty SamAccountName | Disable-ADAccount -Confirm:$false
            $userobject = New-Object -TypeName psobject -Property @{
                UserDisplayName = $value.Name
                UserDesc = $Description
                Username = $value.SamAccountName
                UserManager = $UserManager.DisplayName
                UserManagerEmail = $UserManager.EmailAddress
                UserLastLogonDate = ([datetime]::FromFileTime($DClastdate.RecentLogon))
                UserOU = ($value.DistinguishedName -split ',cn=|,ou=|,dc=')[2]
                UserStagnant = "Yes"
            }
            $stagnantusers += $userobject
        }
    }

    if ($stagnantusers)
    {
        $stagnantusers | select UserDisplayName,Username,UserOU,UserStagnant,UserLastLogonDate,UserManager,UserManagerEmail | export-csv -path $ExportFileName -NoTypeInformation
        $outputmessage = "***AUTOMATED MESSAGE***`n`nPlease see attached CSV for report`n`nReport also available here: <path>"
        Send-MailMessage -To $outputrecipients -From $outputsender -Subject "Stagnant Account Check" -Body $outputmessage -Attachments $ExportFileName -SmtpServer "smtp.whatever.org" -UseSsl
    }elseif (!$stagnantusers) {
        $outputmessage = "***AUTOMATED MESSAGE***`n`nNo stagnant users have been found! Report CSV will not be generated.`n`nPrevious reports also available here: <path>"
        Send-MailMessage -To $outputrecipients -From $outputsender -Subject "Stagnant Account Check" -Body $outputmessage -SmtpServer "smtp.whatever.org" -UseSsl
    }
