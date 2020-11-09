# PuSH

PowerShell command line helpers for Azure DevOps.

## Commands

The purpose of PuSH is to give development teams quick access to vital Azure DevOps capabilities.
It's designed to quickly answer your questions about your project and take appropriate action.

* Get-Builds

### Get-Builds

Lists the builds that are available in the continuous integration pipeline.

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
```

Use the `Register-VSTS` command to set up your connection to VSTS.

## Get Started

Follow these [setup instructions](setup.md) to get started.