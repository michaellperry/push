$PushModule = Get-Module Push
If ($PushModule -ne $Null)
{
    Remove-Module Push
}

Import-Module .\Push.psm1

Write-Host
Write-Host "To get started, run Register-VSTeam"
