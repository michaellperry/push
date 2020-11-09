# Get Started

The install process guides you through the configuration of your VSTS service and your environments. When you are done, you will have configuration files in your project to share with your team. You will also have secrets stored in the Windows Credential Manager so that they are kept safe.

## Install the module

Start a PowerShell command line as an administrator, download the source code from this repository, and run:

```powershell
PS C:\Projects\Push> .\Install.ps1

To get started, run Register-VSTS
```

This will install dependent modules like [CredentialManager](https://www.powershellgallery.com/packages/CredentialManager/2.0)

## Register VSTS

Change directories to your own project and run:

```powershell
PS C:\Projects\tardis2.0> Register-VSTS
This command registers a VSTS Team hosted at https://xxxx.visualstudio.com. Please provide the name (the xxxx part).

    Register-VSTS -TeamName xxxx
```

Run the command again, specifying the name of your VSTS team.

```powershell
PS C:\Projects\tardis2.0> Register-VSTS -TeamName michaellperry
Registering https://michaellperry.visualstudio.com.

You will need to create a personal access token. Go to https://michaellperry.visualstudio.com/_details/security/tokens to create one.

Paste your personal access token from https://michaellperry.visualstudio.com/_details/security/tokens: *******************
Saving personal access token for https://michaellperry.visualstudio.com.

You have registered https://michaellperry.visualstudio.com. Select a project and run:

   Register-VSTS -ProjectName xxxx

name
----
tardis20
Assisticant
Schemavolution
Pree
```

Follow the prompts to set up your personal access token. Run the command again, specifying the name of the project.

```powershell
PS C:\Projects\tardis2.0> Register-VSTS -ProjectName tardis20
Registering https://michaellperry.visualstudio.com project tardis20.

Select a pipeline and run:

   Register-VSTS -PipelineName xxxx

name
----
Tardis Web
Tardis 2.0 DDNUG
tardis20-Visual Studio-CI
```

If you haven't configured your CI build, take the time to do that, and then just type `Register-VSTS` to make sure it appears in the list. Then run the command to select the pipeline.

```powershell
PS C:\Projects\tardis2.0> Register-VSTS -PipelineName "Tardis Web"
Registering pipeline Tardis Web.

Team https://michaellperry.visualstudio.com, project tardis20, pipeline 42 is registered.
```

Pro tip: If you want to do this in fewer steps, you can specify several parameters at once.

At this point, your personal access token has been saved in the Windows Credential Manager, and you have an XML file that you can add to your project. That will make it easier for the rest of your team to get registered, as they will only need to provide their personal access tokens.

```xml
<vsts teamName="michaellperry" projectName="tardis20" pipelineId="42">
</vsts>
```

Open an issue or contact me on twitter at [@michaellperry](https://twitter.com/michaellperry) if you have any questions. Good luck!
