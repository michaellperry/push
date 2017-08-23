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

Select a build definition and run:

   Register-VSTS -BuildDefinitionName xxxx

name
----
Tardis Web
Tardis 2.0 DDNUG
tardis20-Visual Studio-CI
```

If you haven't configured your CI build, take the time to do that, and then just type `Register-VSTS` to make sure it appears in the list. Then run the command to select the build definition.

```powershell
PS C:\Projects\tardis2.0> Register-VSTS -BuildDefinitionName "Tardis Web"
Registering build definition Tardis Web.

Your next step should be to register an environment to which to push builds.

    Register-Environment

Team https://michaellperry.visualstudio.com, project tardis20, build definition Tardis Web is registered.
```

Pro tip: If you want to do this in fewer steps, you can specify several parameters at once.

At this point, your personal access token has been saved in the Windows Credential Manager, and you have an XML file that you can add to your project. That will make it easier for the rest of your team to get registered, as they will only need to provide their personal access tokens.

```xml
<vsts teamName="michaellperry" projectName="tardis20" buildDefinitionName="Tardis Web">
</vsts>
```

## Register an Environment

Like the instructions say, your next step is to register a new environment. You can set up as many of these as you want, for example dev, qa, staging, and prod. An environment consists of a web server and a SQL server.

```powershell
PS C:\Projects\tardis2.0> Register-Environment
This command registers a new environment to which to push builds. Specify an environment name:

    Register-Environment xxxx
```

Run the command again to specify the environment name.

```powershell
PS C:\Projects\tardis2.0> Register-Environment qa

Provide the name of the web server.

    Register-Environment qa -WebServerName xxxx
```

Specify the web server name. You will be prompted for the username and password.

```powershell
PS C:\Projects\tardis2.0> Register-Environment qa -WebServerName 40.112.190.225

I'll need to be able to log in to the web server 40.112.190.225.

User name: mperry
Password: ***************
Saving login credentials for 40.112.190.225.
Now provide the name of the SQL server.

    Register-Environment qa -SqlServerName xxxx
```

Call it again to specify the SQL server. You will be prompted for your SQL credentials.

```powershell
PS C:\Projects\tardis2.0> Register-Environment qa -SqlServerName tardissql.database.windows.net

Please provide the user name and password for the SQL server tardissql.database.windows.net so that I can migrate the database and generate the connection string.

User name: mperry
Password: *********
Saving login credentials for tardissql.database.windows.net.
Finally, I'll need the name of the application database.

    Register-Environment qa -DatabaseName xxxx
```

Now that you have the server configured, specify the name of the database.

```powershell
PS C:\Projects\tardis2.0> Register-Environment qa -DatabaseName tardisdb

The qa environment is registered. If this is a new environment, you might need to enable web server features:

    Enable-WebServerFeatures qa
```

One again, you can specify multiple parameters at once. You'll end up with secrets in Windows Credential Manager, and everything else in an XML file to share with your team.

```xml
<environments>
  <environment name="qa" webServerName="40.112.190.225" sqlServerName="tardissql.database.windows.net" databaseName="tardisdb" />
</environments>
```

## Enable Web Server Features

A brand new Windows Server VM in Azure or AWS is not configured to be a web server. That's OK. We can fix that in one command. However, before we can run this command, you have to make sure that we can access the machine.

- Add an inbound security rule allowing the WinRM port (5986) to the network security group.
- Open a remote desktop connection to the web server and run the `enable-psh-remoting.ps1` script, located in the Helpers folder. This script:
    - Creates a self-signed certificate
    - Creates a WinRM listener for HTTPS
    - Allows port 5986 through the Windows firewall
- Add an inbound security rule for HTTP (80) or HTTPS (443), whichever your application requires.

The rest can be done via the `Enable-WebServerFeatures` command. This takes a while, but it does the following for you:

- Turns on IIS, .NET Framework, and ASP.NET Windows features required to run ASP.NET applications.
- Installs [Chocolatey](https://chocolatey.org)
- Installs Web Deploy

This is also your first test of your web server credentials.

## Add Database Migrations to your Project

Within your solution, one of the projects is the data access layer. This project probably has Entity Framework migrations. If so, copy the `Migrate.ps1` script from the Helpers folder into the project. Also add the `migrate.exe` file from `packages\EntityFramework.6.1.3\tools`. Configure both as:

- Build Action: Content
- Copy to Output Directory: Copy always

Edit the migrate script to specify the name of your DLL.

If you do not use Entity Framework Migrations, not to worry. Just write your own `Migrate.ps1` and run the migrations using the supplied connection string.

## Configure your Project

Your project needs to produce a web deployment package. Righ-click on the web project and select Publish. Select the following options:

- Publish method: Web Deploy Package
- Package location: deploy\MyApplication.zip
- Site name: Default Web Site/
- Configuration: Release
- Settings: DefaultConnection

On the VSTS build, set the following MSBuild command line arguments:

```
/p:DeployOnBuild=true /p:PublishProfile=CustomProfile /p:OutputPath="$(Build.SourcesDirectory)\_build"
```

Then add a step to the build that copies and publishes the web deploy package as a build artifact:

- Add task: Copy and Pulish Build Artifacts
- Display name: Copy Publish Artifact: WebDeploymentPackage
- Contents: `_build\_PublishedWebsites\MyApplication_Package\**`
- Artifact name: WebDeploymentPackage
- Artifact type: Server

Queue up a build. Then check the artifacts to ensure that `WebDeploymentPackage` was created. It should contain:

- MyApplication.deploy-readme.txt
- MyApplication.deploy.cmd
- MyApplication.SetParameters.xml
- MyApplication.SourceManifest.xml
- MyApplication.zip

You might also see a `drop` artifact. That one is not important for this pipeline.

Test your configuration by pushing a build to your new environment. Open an issue or contact me on twitter at [@michaellperry](https://twitter.com/michaellperry) if you have any questions. Good luck!
