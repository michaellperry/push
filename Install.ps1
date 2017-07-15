If ((Get-Module CredentialManager) -eq $Null)
{
    Install-Module CredentialManager -Force
}

If ((Get-Module Push) -ne $Null)
{
    Remove-Module Push
}

Import-Module .\Push.psm1

Write-Host
Write-Host "To get started, run Register-VSTS"
