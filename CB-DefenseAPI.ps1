#Defaults
$Script:Token = $null
$ApiHost = 'https://yourinstance.conferdeploy.net/integrationServices/v3'

function Invoke-CbApi{
    param(
        [string]$Command,
        [ValidateSet('Get','Delete','Post','Put','Patch')]
        [string]$Method='Get',
        [string]$JsonBody
    )

    If($Script:Token -eq $null){
        $Script:Token = 'apikey/connectorstring'
    }

    If($JsonBody -and $Method){
        return Invoke-WebRequest -UseBasicParsing -Uri "$ApiHost/$Command" -Headers @{'X-Auth-Token'=$Token;'Content-Type'='application/json'} -Method $Method -Body $JsonBody -ContentType application/json
    }Else{
        return Invoke-WebRequest -UseBasicParsing -Uri "$ApiHost/$Command" -Headers @{'X-Auth-Token'=$Token} -Method $Method -ContentType application/json
    }
}

$System = Read-Host -Prompt 'Enter host name'

Write-Host "`n===============CB DEFENSE===============`n" -ForegroundColor Yellow
$DefResponse = (Invoke-CbApi -Command "device?hostName=$System").Content | ConvertFrom-Json | Select -ExpandProperty results
$DefResponse = [PSCustomObject]$DefResponse
$DefResponse | select * | ft -Property name,status,sensorVersion,osVersion,lastContact