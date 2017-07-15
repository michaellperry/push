Add-Type -Assembly "System.IO.Compression.Filesystem"

function Register-VSTS {
param(
    [string] $TeamName = "",
    [string] $ProjectName = "",
    [string] $BuildDefinitionName = ""
)

    If ((Test-Path "$pwd\VSTSConfig.xml") -eq $False)
    {
        [xml]$EmptyConfig = New-Object System.XML.XMLDocument
        $EmptyConfig.LoadXml("<vsts></vsts>")
        $EmptyConfig.Save("$pwd\VSTSConfig.xml")
    }

    [xml]$Config = Get-Content "$pwd\VSTSConfig.xml"
    $VSTS = $Config.FirstChild

    $TeamNameAttribute = $VSTS.Attributes["teamName"]
    If ($TeamNameAttribute -eq $Null)
    {
        If ($TeamName -eq "")
        {
            Write-Host "This command registers a VSTS Team hosted at https://xxxx.visualstudio.com. Please provide the name (the xxxx part)."
            Write-Host
            Write-Host "    Register-VSTeam -TeamName xxxx"
            break
        }

        Write-Host "Registering https://$TeamName.visualstudio.com."
        $TeamNameAttribute = $Config.CreateAttribute("teamName")
        $TeamNameAttribute.Value = $TeamName
        $VSTS.Attributes.Append($TeamNameAttribute)
        $Config.Save("$pwd\VSTSConfig.xml")
    }
    Else
    {
        $TeamName = $TeamNameAttribute.Value
    }

    $Credential = Get-StoredCredential -Target "$TeamName.visualstudio.com"
    If ($Credential -eq $Null)
    {
        Write-Host "You will need to create a personal access token. Go to https://$TeamName.visualstudio.com/_details/security/tokens to create one."
        Write-Host

        $PersonalAccessToken = Read-Host "Paste your personal access token from https://$TeamName.visualstudio.com/_details/security/tokens" -AsSecureString
        Write-Host "Saving personal access token for https://$TeamName.visualstudio.com."
        $Credential = New-StoredCredential -Target "$TeamName.visualstudio.com" -UserName $TeamName -SecurePassword $PersonalAccessToken -Persist Enterprise
    }

    $Password = $Credential.GetNetworkCredential().Password
    $BasicAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Password)"))

    $ProjectNameAttribute = $VSTS.Attributes["projectName"]
    If ($ProjectNameAttribute -eq $Null)
    {
        If ($ProjectName -eq "")
        {
            $Projects = Invoke-RestMethod `
                -Headers @{ Authorization = $BasicAuth } `
                -Uri "https://$TeamName.visualstudio.com/DefaultCollection/_apis/projects?api-version=2.0"

            Write-Host "You have registered https://$TeamName.visualstudio.com. Select a project and run:"
            Write-Host
            Write-Host "   Register-VSTS -ProjectName xxxx"

            $Projects.Value | Format-Table Name

            break
        }

        $Project = Invoke-RestMethod `
            -Headers @{ Authorization = $BasicAuth } `
            -Uri "https://$TeamName.visualstudio.com/DefaultCollection/_apis/projects/$($ProjectName)?api-version=2.0"

        Write-Host "Registering https://$TeamName.visualstudio.com project $ProjectName."
        $ProjectNameAttribute = $Config.CreateAttribute("projectName")
        $ProjectNameAttribute.Value = $ProjectName
        $VSTS.Attributes.Append($ProjectNameAttribute)
        $Config.Save("$pwd\VSTSConfig.xml")
    }
    Else
    {
        $ProjectName = $ProjectNameAttribute.Value
    }

    $BuildDefinitionNameAttribute = $VSTS.Attributes["buildDefinitionName"]
    If ($BuildDefinitionNameAttribute -eq $Null)
    {
        If ($BuildDefinitionName -eq "")
        {
            $BuildDefinitions = Invoke-RestMethod `
                -Headers @{ Authorization = $BasicAuth } `
                -Uri "https://$TeamName.visualstudio.com/DefaultCollection/$ProjectName/_apis/build/definitions?api-version=2.0"

            Write-Host "Select a build definition and run:"
            Write-Host
            Write-Host "   Register-VSTS -BuildDefinitionName xxxx"

            $BuildDefinitions.Value | Format-Table Name

            break
        }

        $BuildDefinitions = Invoke-RestMethod `
            -Headers @{ Authorization = $BasicAuth } `
            -Uri "https://$TeamName.visualstudio.com/DefaultCollection/$ProjectName/_apis/build/definitions?api-version=2.0&name=$([System.Web.HttpUtility]::UrlEncode($BuildDefinitionName))"

        If ($BuildDefinitions.Value.Count -eq 0)
        {
            Write-Host "The build definition $BuildDefinitionName was not found in https://$TeamName.visualstudio.com, project $ProjectName. To list the build definitions again run:"
            Write-Host
            Write-Host "   Register-VSTS"

            break
        }

        Write-Host "Registering build definition $BuildDefinitionName."
        $BuildDefinitionNameAttribute = $Config.CreateAttribute("buildDefinitionName")
        $BuildDefinitionNameAttribute.Value = $BuildDefinitionName
        $VSTS.Attributes.Append($BuildDefinitionNameAttribute)
        $Config.Save("$pwd\VSTSConfig.xml")
    }
    Else
    {
        $BuildDefinitionName = $BuildDefinitionNameAttribute.Value
    }

    Write-Output "Team https://$TeamName.visualstudio.com, project $ProjectName, build definition $BuildDefinitionName is registered."
}

function Get-VSTSConfig {
    [xml]$Config = Get-Content "$pwd\VSTSConfig.xml"
    $TeamName = $Config.vsts.teamName
    $ProjectName = $Config.vsts.projectName
    $BuildDefinitionName = $Config.vsts.buildDefinitionName

    $Credential = Get-StoredCredential -Target "$TeamName.visualstudio.com"
    $Password = $Credential.GetNetworkCredential().Password
    $BasicAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Password)"))

    return @{ `
        TeamName = $TeamName; `
        ProjectName = $ProjectName; `
        BuildDefinitionName = $BuildDefinitionName; `
        BasicAuth = $BasicAuth; `
    }
}

function Get-Builds {
    $Config = Get-VSTSConfig

    $BuildDefinitions = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri "https://$($Config.TeamName).visualstudio.com/DefaultCollection/$($Config.ProjectName)/_apis/build/definitions?api-version=2.0&name=$([System.Web.HttpUtility]::UrlEncode($Config.BuildDefinitionName))"
    $BuildDefinitionId = $BuildDefinitions.Value[0].Id

    $Builds = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri "https://$($Config.TeamName).visualstudio.com/DefaultCollection/$($Config.ProjectName)/_apis/build/builds?definitions=$BuildDefinitionId&$('$top')=10&api-version=2.0"

    $Builds.Value | Format-Table `
        @{ Label = "Build"; Expression = { $_.BuildNumber } }, `
        @{ Label = "For"; Expression = { $_.RequestedFor.DisplayName } }, `
        @{ Label = "Result"; Expression = { $_.Result } }, `
        @{ Label = "Completed"; Expression = { [DateTime]::Parse($_.FinishTime).ToString("G") } }
}

function Push-Build {
param(
    [string] $Environment,
    [string] $Build
)

    $Config = Get-VSTSConfig
    $ArtifactName = "WebDeploymentPackage"

    $BuildDefinitions = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri "https://$($Config.TeamName).visualstudio.com/DefaultCollection/$($Config.ProjectName)/_apis/build/definitions?api-version=2.0&name=$([System.Web.HttpUtility]::UrlEncode($Config.BuildDefinitionName))"
    $BuildDefinitionId = $BuildDefinitions.Value[0].Id

    $Builds = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri "https://$($Config.TeamName).visualstudio.com/DefaultCollection/$($Config.ProjectName)/_apis/build/builds?definitions=$BuildDefinitionId&buildNumber=$Build&api-version=2.0"
    $BuildId = $Builds.Value[0].Id

    $Artifacts = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri "https://$($Config.TeamName).visualstudio.com/DefaultCollection/$($Config.ProjectName)/_apis/build/builds/$BuildId/artifacts?api-version=2.0"
    $ArtifactUrl = $Artifacts.Value | ?{ $_.Name -eq $ArtifactName } | %{ $_.Resource.DownloadUrl }

    If (Test-Path "$pwd\DeploymentFiles")
    {
        Remove-Item "$pwd\DeploymentFiles" -Recurse
    }
    mkdir "$pwd\DeploymentFiles"

    $Artifacts = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri $ArtifactUrl `
        -OutFile "$pwd\DeploymentFiles\WebDeploymentPackage.zip"

    [IO.Compression.ZipFile]::ExtractToDirectory("$pwd\DeploymentFiles\WebDeploymentPackage.zip", "$pwd\DeploymentFiles")
}

Export-ModuleMember -Function Register-VSTS, Get-Builds, Push-Build