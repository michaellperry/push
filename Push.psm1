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
    If ((Test-Path "$pwd\VSTSConfig.xml") -eq $False)
    {
        [xml]$EmptyConfig = New-Object System.XML.XMLDocument
        $EmptyConfig.LoadXml("<teams></teams>")
        $EmptyConfig.Save("$pwd\VSTSConfig.xml")
    }

    [xml]$Config = Get-Content "$pwd\VSTSConfig.xml"
    $Teams = $Config.FirstChild
    $Team = $Config.CreateElement("team")
    $Team.SetAttribute("name", $Name)
    $Teams.AppendChild($Team)
    $Config.Save("$pwd\VSTSConfig.xml")
}

Export-ModuleMember -Function Register-VSTeam