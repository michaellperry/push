# PuSH
Turnkey deployment mechanism for continuous delivery of .NET applications through PowerShell.

## Two Commands
The purpose of the PuSH mechanism is to help teams deliver continuous value to cloud or on-premises environments from a continuous integration pipeline. It puts the control over which version of the software is in which environment entirely in the hands of the development, testing, and delivery team. And it's all done using two PowerShell commands:

* Get-Builds
* Push-Build

### Get-Builds
Lists the builds that are available in the continuous integration pipeline. The only pipeline supported at this time is VSTS.

```
PS C:\Projects\Push> Get-Builds

Build      For             Result    Completed            
-----      ---             ------    ---------            
20170716.5 Michael L Perry succeeded 7/16/2017 10:46:21 AM
20170716.4 Michael L Perry succeeded 7/16/2017 10:11:32 AM
20170716.3 Michael L Perry succeeded 7/16/2017 10:10:18 AM
20170716.2 Michael L Perry succeeded 7/16/2017 9:54:11 AM 
20170716.1 Michael L Perry succeeded 7/16/2017 9:50:48 AM 
20170517.2 Michael L Perry succeeded 5/16/2017 7:40:16 PM 


You can deploy the latest successful build:

   Push-Build dev 20170716.5
```

Use the `Register-VSTS` command to set up your connection to VSTS.

Once you determine which build you want to push, call `Push-Build`.

### Push-Build
Pushes a build to a target environment. Target environments are networks of virtual machines, either on-premises or in the cloud. They have been configured ahead of time using the `Register-Environment` command.

```
PS C:\MyProject\Push> Push-Build test 20170428.4
```

This will deploy the web application to the web server, and run the database migrations on the SQL database.

## Get Started

Follow these [setup instructions](setup.md) to get started.