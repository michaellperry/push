function Register-VSTeam {
param(
    [string] $Name = ""
)

    If ($Name -eq "")
    {
        Write-Host "This command registeres a VSTS Team hosted at https://xxxx.visualstudio.com. Please provide the name (the xxxx part)."
        Write-Host
        Write-Host "    Register-VSTeam xxxx"
        break
    }

    Write-Host "Registering https://$Name.visualstudio.com"
}

Export-ModuleMember -Function Register-VSTeam