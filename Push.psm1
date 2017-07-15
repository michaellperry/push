﻿
function Register-VSTeam {
param(
    [string] $Name = "",
    [string] $PersonalAccessToken = ""
)

    If ((Test-Path "$pwd\VSTSConfig.xml") -eq $False)
    {
        [xml]$EmptyConfig = New-Object System.XML.XMLDocument
        $EmptyConfig.LoadXml("<team></team>")
        $EmptyConfig.Save("$pwd\VSTSConfig.xml")
    }

    [xml]$Config = Get-Content "$pwd\VSTSConfig.xml"
    $Team = $Config.FirstChild
    $TeamName = $Team.Attributes["name"]

    If ($TeamName -eq $Null)
    {
        If ($Name -eq "")
        {
            Write-Host "This command registeres a VSTS Team hosted at https://xxxx.visualstudio.com. Please provide the name (the xxxx part)."
            Write-Host
            Write-Host "    Register-VSTeam xxxx"
            break
        }

        $TeamName = $Config.CreateAttribute("name")
        $TeamName.Value = $Name
        $Team.Attributes.Append($TeamName)
        $Config.Save("$pwd\VSTSConfig.xml")
    }

    $Credential = Get-StoredCredential -Target "$Name.visualstudio.com"
    If ($Credential -eq $Null)
    {
        If ($PersonalAccessToken -eq "")
        {
            Write-Host "You will need to create a personal access token. Go to https://$Name.visualstudio.com/_details/security/tokens to create one. Then run:"
            Write-Host
            Write-Host "    Register-VSTeam $Name xxxx"
            break
        }
    }

}

Export-ModuleMember -Function Register-VSTeam