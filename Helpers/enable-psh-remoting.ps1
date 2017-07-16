# Enable remote Powershell access:
#  - Add WinRM HTTPS listener using a self-signed certificate
#  - Add a firewall rule to allow inbound traffic on TCP port 5986 (Remote Powershell over HTTPS)
#
# Reference: 
#   http://www.techdiction.com/2016/02/11/configuring-winrm-over-https-to-enable-powershell-remoting/

[CmdletBinding()]
param (
  [Parameter(Mandatory=$true)]
  [string] $publicDnsName = $null
)

$cert = New-SelfSignedCertificate -DnsName $publicDnsName -CertStoreLocation Cert:\LocalMachine\My

Write-Output "`r`nSelf-Signed Certificate: Subject='$($cert.Subject)', Thumbprint='$($cert.Thumbprint)' `r`n"

$createListener = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$publicDnsName`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
$deleteListener = "winrm delete winrm/config/Listener?Address=*+Transport=HTTPS"

Write-Output $createListener

$command = "cmd.exe /C '$createListener'"
$result = Invoke-Expression $command
Write-Output $result

Invoke-Expression "winrm enumerate winrm/config/listener"

$ruleName = "WinRM HTTPS"
$rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue

if (!$rule)
{
  $rule = New-NetFirewallRule -Name $ruleName -DisplayName "WinRM HTTPS" `
            -Action Allow `
            -Profile Any `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 5986
}  


Write-Output "Windows Firewall:"
Write-Output $rule
