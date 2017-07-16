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
            Write-Host "    Register-VSTS -TeamName xxxx"
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

    return
}

function Register-Environment {
param(
    [string] $Name = "",
    [string] $WebServerName = "",
    [string] $SqlServerName = "",
    [string] $DatabaseName = ""
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

    $SqlServerNameAttribute = $Environment.Attributes["sqlServerName"]
    If ($SqlServerNameAttribute -eq $Null)
    {
        If ($SqlServerName -eq "")
        {
            Write-Host "Now provide the name of the SQL server."
            Write-Host
            Write-Host "    Register-Environment $Name -SqlServerName xxxx"

            break
        }

        $SqlServerNameAttribute = $Config.CreateAttribute("sqlServerName")
        $SqlServerNameAttribute.Value = $SqlServerName
        $Environment.Attributes.Append($SqlServerNameAttribute)
        $Config.Save("$pwd\EnvironmentsConfig.xml")
    }
    Else
    {
        $SqlServerName = $SqlServerNameAttribute.Value
    }

    $SqlServerCredential = Get-StoredCredential -Target $SqlServerName
    If ($SqlServerCredential -eq $Null)
    {
        Write-Host "Please provide the user name and password for the SQL server $SqlServerName so that I can migrate the database and generate the connection string."
        Write-Host

        $SqlServerUserName = Read-Host "User name"
        $SqlServerPassword = Read-Host "Password" -AsSecureString
        Write-Host "Saving login credentials for $SqlServerName."
        $SqlServerCredential = New-StoredCredential -Target $SqlServerName -UserName $SqlServerUserName -SecurePassword $SqlServerPassword -Persist Enterprise
    }

    $DatabaseNameAttribute = $Environment.Attributes["databaseName"]
    If ($DatabaseNameAttribute -eq $Null)
    {
        If ($DatabaseName -eq "")
        {
            Write-Host "Finally, I'll need the name of the application database."
            Write-Host
            Write-Host "    Register-Environment $Name -DatabaseName xxxx"

            break
        }

        $DatabaseNameAttribute = $Config.CreateAttribute("databaseName")
        $DatabaseNameAttribute.Value = $DatabaseName
        $Environment.Attributes.Append($DatabaseNameAttribute)
        $Config.Save("$pwd\EnvironmentsConfig.xml")
    }
    Else
    {
        $DatabaseName = $DatabaseNameAttribute.Value
    }

    Write-Host "The $Name environment is registered. If this is a new environment, you might need to enable web server features:"
    Write-Host
    Write-Host "    Enable-WebServerFeatures $Name"

    return
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
    $SqlServerName = $Environment.sqlServerName
    $DatabaseName = $Environment.databaseName

    $WebServerCredential = Get-StoredCredential -Target $WebServerName
    $SqlServerCredential = Get-StoredCredential -Target $SqlServerName
    $Password = $SqlServerCredential.GetNetworkCredential().Password
    $ConnectionString = "Data Source=$SqlServerName;Initial Catalog=$DatabaseName;User ID=$($SqlServerCredential.UserName);Password=$Password;"

    return @{ `
        WebServerName = $WebServerName; `
        WebServerCredential = $WebServerCredential; `
        ConnectionString = $ConnectionString; `
    }
}

function Enable-WebServerFeatures {
param(
    [Parameter(Mandatory=$True)]
    [string] $Environment
)

    $EnvironmentConfig = Get-EnvironmentConfig($Environment)

    $WebServerFeatures = @( `
      "Web-Default-Doc", `
      "Web-Dir-Browsing", `
      "Web-Http-Errors", `
      "Web-Static-Content", `
      "Web-Http-Logging", `
      "Web-Stat-Compression", `
      "Web-Filtering", `
      "Web-Net-Ext45", `
      "Web-Asp-Net45", `
      "Web-ISAPI-Ext", `
      "Web-ISAPI-Filter", `
      "Web-Mgmt-Console", `
      "Web-Mgmt-Service"
      "NET-Framework-Features", `
      "NET-Framework-Core", `
      "NET-HTTP-Activation", `
      "NET-Framework-45-ASPNET")

    $PSSessionOptions = New-PSSessionOption –SkipCACheck -SkipCNCheck
    $PSSession = New-PSSession $EnvironmentConfig.WebServerName -credential $EnvironmentConfig.WebServerCredential -UseSSL -SessionOption $PSSessionOptions

    Invoke-Command -Session $PSSession -ScriptBlock {
        Install-WindowsFeature -Name $Using:WebServerFeatures
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        choco install webdeploy -y
    }

    Remove-PSSession $PSSession

    return
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

    [array]$SuccessfulBuilds = $Builds.Value | ?{ $_.Result -eq "succeeded" } | %{ $_.BuildNumber }
    If ($SuccessfulBuilds.Count -ne 0)
    {
        [xml]$Config = Get-Content "$pwd\EnvironmentsConfig.xml"
        $Environment = $config.SelectSingleNode("/environments/environment")

        Write-Host "You can deploy the latest successful build:"
        Write-Host
        Write-Host "   Push-Build $($Environment.name) $($SuccessfulBuilds[0])"
    }
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
    mkdir "$pwd\DeploymentFiles" | Out-Null
    mkdir "$pwd\DeploymentFiles\Download" | Out-Null
    mkdir "$pwd\DeploymentFiles\Extract" | Out-Null
    mkdir "$pwd\DeploymentFiles\Upload" | Out-Null

    $Artifacts = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -Uri $ArtifactUrl `
        -OutFile "$pwd\DeploymentFiles\Download\WebDeploymentPackage.zip"

    [IO.Compression.ZipFile]::ExtractToDirectory("$pwd\DeploymentFiles\Download\WebDeploymentPackage.zip", "$pwd\DeploymentFiles\Extract")
    $WebDeployCommand = Get-Item "$pwd\DeploymentFiles\Extract\WebDeploymentPackage\*.deploy.cmd" | %{ $_.Name }
    $SetParametersFile = Get-Item "$pwd\DeploymentFiles\Extract\WebDeploymentPackage\*.SetParameters.xml" | %{ $_.FullName }

    [xml]$Parameters = Get-Content $SetParametersFile
    $ConnectionStringAttribute = $Parameters.SelectSingleNode("/parameters/setParameter[@name='DefaultConnection-Web.config Connection String']")
    $ConnectionStringAttribute.Value = $EnvironmentConfig.ConnectionString
    $Parameters.Save($SetParametersFile)

    [IO.Compression.ZipFile]::CreateFromDirectory("$pwd\DeploymentFiles\Extract", "$pwd\DeploymentFiles\Upload\WebDeploymentPackage.zip")

    $PSSessionOptions = New-PSSessionOption –SkipCACheck -SkipCNCheck
    $PSSession = New-PSSession $EnvironmentConfig.WebServerName -credential $EnvironmentConfig.WebServerCredential -UseSSL -SessionOption $PSSessionOptions

    Invoke-Command -Session $PSSession -ScriptBlock {
        If (Test-Path "C:\DeploymentFiles")
        {
            Remove-Item "C:\DeploymentFiles" -Recurse
        }
        mkdir "C:\DeploymentFiles" | Out-Null
        mkdir "C:\DeploymentFiles\Download" | Out-Null
        mkdir "C:\DeploymentFiles\Extract" | Out-Null
    }
    Copy-Item -Path "$pwd\DeploymentFiles\Upload\WebDeploymentPackage.zip" -Destination "C:\DeploymentFiles\Download" -ToSession $PSSession
    Invoke-Command -Session $PSSession -ScriptBlock {
        Add-Type -Assembly System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory("C:\DeploymentFiles\Download\WebDeploymentPackage.zip", "C:\DeploymentFiles\Extract")
        cd C:\DeploymentFiles\Extract\WebDeploymentPackage
        & ".\$Using:WebDeployCommand" @( "/Y" )
        C:\inetpub\wwwroot\bin\Migrate.ps1 $Using:EnvironmentConfig.ConnectionString
    }

    Remove-PSSession $PSSession
}

Export-ModuleMember -Function Register-VSTS, Register-Environment, Enable-WebServerFeatures, Get-Builds, Push-Build