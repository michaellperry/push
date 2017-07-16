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

        Write-Host
        Write-Host "Your next step should be to register an environment to which to push builds."
        Write-Host
        Write-Host "    Register-Environment"
    }
    Else
    {
        $BuildDefinitionName = $BuildDefinitionNameAttribute.Value
    }

    Write-Output "Team https://$TeamName.visualstudio.com, project $ProjectName, build definition $BuildDefinitionName is registered."
}

function Register-Environment {
param(
    [string] $Name = "",
    [string] $WebServerName = ""
)

    If ($Name -eq "")
    {
        Write-Host "This command registers a new environment to which to push builds. Specify an environment name:"
        Write-Host
        Write-Host "    Register-Environment xxxx"

        break
    }

    If ((Test-Path "$pwd\EnvironmentsConfig.xml") -eq $False)
    {
        [xml]$EmptyConfig = New-Object System.XML.XMLDocument
        $EmptyConfig.LoadXml("<environments></environments>")
        $EmptyConfig.Save("$pwd\EnvironmentsConfig.xml")
    }

    [xml]$Config = Get-Content "$pwd\EnvironmentsConfig.xml"
    $Environments = $Config.FirstChild
    $Environment = $Environments.SelectSingleNode("environment[@name='$Name']")
    If ($Environment -eq $Null)
    {
        $Environment = $Config.CreateElement("environment")
        $EnvironmentNameAttribute = $Config.CreateAttribute("name")
        $EnvironmentNameAttribute.Value = $Name
        $Environment.Attributes.Append($EnvironmentNameAttribute)
        $Environments.AppendChild($Environment)
        $Config.Save("$pwd\EnvironmentsConfig.xml")
    }

    $WebServerNameAttribute = $Environment.Attributes["webServerName"]
    If ($WebServerNameAttribute -eq $Null)
    {
        If ($WebServerName -eq "")
        {
            Write-Host "Provide the name of the web server."
            Write-Host
            Write-Host "    Register-Environment $Name -WebServerName xxxx"

            break
        }

        $WebServerNameAttribute = $Config.CreateAttribute("webServerName")
        $WebServerNameAttribute.Value = $WebServerName
        $Environment.Attributes.Append($WebServerNameAttribute)
        $Config.Save("$pwd\EnvironmentsConfig.xml")
    }
    Else
    {
        $WebServerName = $WebServerNameAttribute.Value
    }

    $WebServerCredential = Get-StoredCredential -Target $WebServerName
    If ($WebServerCredential -eq $Null)
    {
        Write-Host "I'll need to be able to log in to the web server $WebServerName."
        Write-Host

        $WebServerUserName = Read-Host "User name"
        $WebServerPassword = Read-Host "Password" -AsSecureString
        Write-Host "Saving login credentials for $WebServerName."
        $WebServerCredential = New-StoredCredential -Target $WebServerName -UserName $WebServerUserName -SecurePassword $WebServerPassword -Persist Enterprise
    }
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

function Get-EnvironmentConfig {
param(
    [string] $EnvironmentName
)

    [xml]$Config = Get-Content "$pwd\EnvironmentsConfig.xml"
    $Environment = $config.SelectSingleNode("/environments/environment[@name='$EnvironmentName']")
    $WebServerName = $Environment.webServerName

    $WebServerCredential = Get-StoredCredential -Target $WebServerName

    Return @{ `
        WebServerName = $WebServerName; `
        WebServerCredential = $WebServerCredential; `
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
    [Parameter(Mandatory=$True)]
    [string] $Environment,

    [Parameter(Mandatory=$True)]
    [string] $Build
)

    $Config = Get-VSTSConfig
    $EnvironmentConfig = Get-EnvironmentConfig($Environment)
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

    $ZipFile = Get-Item "$pwd\DeploymentFiles\WebDeploymentPackage\*.zip" | %{ $_.FullName }
    [IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, "$pwd\DeploymentFiles\Deploy")

    $PSSessionOptions = New-PSSessionOption –SkipCACheck -SkipCNCheck
    $PSSession = New-PSSession $EnvironmentConfig.WebServerName -credential $EnvironmentConfig.WebServerCredential -UseSSL -SessionOption $PSSessionOptions


    Remove-PSSession $PSSession

    # $ManifestFile = Get-Item "$pwd\DeploymentFiles\WebDeploymentPackage\*.SourceManifest.xml" | %{ $_.FullName }
    # [xml]$Manifest = Get-Content $ManifestFile
    # $IisAppPath = $Manifest.sitemanifest.IisApp.path
    # $WebConfigPath = "$pwd\DeploymentFiles\Deploy\Content\$($IisAppPath.Substring(0,1))_C\$($IisAppPath.Substring(3))\web.config"
}

Export-ModuleMember -Function Register-VSTS, Register-Environment, Get-Builds, Push-Build