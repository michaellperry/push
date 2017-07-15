$PushModule = Get-Module Push
If ($PushModule -ne $Null)
{
    Remove-Module Push
}

Install-Module CredentialManager -Force

Import-Module .\Push.psm1

Write-Host
Write-Host "To get started, run Register-VSTeam"
