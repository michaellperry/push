Add-Type -Assembly "System.IO.Compression.Filesystem"

function Register-VSTS {
param(
    [string] $TeamName = "",
    [string] $ProjectName = "",
    [string] $PipelineName = ""
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
        Write-Host "You will need to create a personal access token. Go to https://$TeamName.visualstudio.com/_usersSettings/tokens to create one."
        Write-Host

        $PersonalAccessToken = Read-Host "Paste your personal access token from https://$TeamName.visualstudio.com/_usersSettings/tokens" -AsSecureString
        Write-Host "Saving personal access token for https://$TeamName.visualstudio.com."
        $Credential = New-StoredCredential -Target "$TeamName.visualstudio.com" -UserName $TeamName -SecurePassword $PersonalAccessToken -Persist Enterprise
        $Password = $Credential.Password
    }
    Else
    {
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    }

    $BasicAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Password)"))

    $ProjectNameAttribute = $VSTS.Attributes["projectName"]
    If ($ProjectNameAttribute -eq $Null)
    {
        If ($ProjectName -eq "")
        {
            $Projects = Invoke-RestMethod `
                -Headers @{ Authorization = $BasicAuth } `
                -Uri "https://dev.azure.com/$TeamName/_apis/projects?api-version=6.0"

            Write-Host "You have registered https://$TeamName.visualstudio.com. Select a project and run:"
            Write-Host
            Write-Host "   Register-VSTS -ProjectName xxxx"

            $Projects.Value | Format-Table Name

            break
        }

        $Project = Invoke-RestMethod `
            -Headers @{ Authorization = $BasicAuth } `
            -Uri "https://dev.azure.com/$TeamName/_apis/projects/$($ProjectName)?api-version=6.0"

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

    $PipelineIdAttribute = $VSTS.Attributes["pipelineId"]
    If ($PipelineIdAttribute -eq $Null)
    {
        $Pipelines = Invoke-RestMethod `
            -Headers @{ Authorization = $BasicAuth } `
            -Uri "https://dev.azure.com/$TeamName/$ProjectName/_apis/pipelines?api-version=6.0-preview.1"

        If ($PipelineName -eq "")
        {
            Write-Host "Select a pipeline and run:"
            Write-Host
            Write-Host "   Register-VSTS -PipelineName xxxx"

            $Pipelines.Value | Format-Table Name

            break
        }

        $Pipelines = $Pipelines.Value | Where-Object {$_.Name -eq $PipelineName}

        If ($Pipelines.Count -eq 0)
        {
            Write-Host "The pipeline $PipelineName was not found in https://$TeamName.visualstudio.com, project $ProjectName. To list the pipelines again run:"
            Write-Host
            Write-Host "   Register-VSTS"

            break
        }

        Write-Host "Registering pipeline $PipelineName."
        $PipelineIdAttribute = $Config.CreateAttribute("pipelineId")
        $PipelineIdAttribute.Value = $Pipelines[0].Id
        $VSTS.Attributes.Append($PipelineIdAttribute)
        $Config.Save("$pwd\VSTSConfig.xml")
    }

    $PipelineId = $PipelineIdAttribute.Value

    Write-Host "Team https://$TeamName.visualstudio.com, project $ProjectName, pipeline $PipelineId is registered."

    Write-Host
    Write-Host "You can now list the builds from this pipeline."
    Write-Host
    Write-Host "    Get-Builds"

    return
}

function Get-VSTSConfig {
    [xml]$Config = Get-Content "$pwd\VSTSConfig.xml"
    $TeamName = $Config.vsts.teamName
    $ProjectName = $Config.vsts.projectName
    $PipelineId = $Config.vsts.pipelineId

    $Credential = Get-StoredCredential -Target "$TeamName.visualstudio.com"
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    $BasicAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Password)"))

    return @{ `
        TeamName = $TeamName; `
        ProjectName = $ProjectName; `
        PipelineId = $PipelineId; `
        BasicAuth = $BasicAuth; `
    }
}

function Get-Builds {
    $Config = Get-VSTSConfig

    $PipelineId = $Config.PipelineId

    $Builds = Invoke-RestMethod `
        -Headers @{ Authorization = $Config.BasicAuth } `
        -ContentType "application/json" `
        -Uri "https://dev.azure.com/$($Config.TeamName)/$($Config.ProjectName)/_apis/build/builds?definitions=$($Config.PipelineId)&$('$top')=10&api-version=6.0"

    $Builds.Value | Format-Table `
        @{ Label = "Build"; Expression = { $_.BuildNumber } }, `
        @{ Label = "For"; Expression = { $_.RequestedFor.DisplayName } }, `
        @{ Label = "Result"; Expression = { $_.Result } }, `
        @{ Label = "Comment"; Expression = { $_.TriggerInfo."ci.message" } }, `
        @{ Label = "Completed"; Expression = { [DateTime]::Parse($_.FinishTime).ToString("G") } }
}

Export-ModuleMember -Function Register-VSTS, Get-Builds