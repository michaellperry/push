# PuSH
Turnkey deployment mechanism for continuous delivery of .NET applications through PowerShell.

## Two Commands
The purpose of the PuSH mechanism is to help teams deliver continuous value to cloud or on-premises environments from a continuous integration pipeline. It puts the control over which version of the software is in which environment entirely in the hands of the development, testing, and delivery team. And it's all done using two PowerShell commands:

* Get-Builds
* Push-Build

### Get-Builds
Lists the builds that are available in the continuous integration pipeline. The only pipeline supported at this time is VSTS.

```
PS C:\MyProject\PuSH> .\Get-Builds.ps1

BuildNumber Date                Result    User                       Commit Comment
----------- ----                ------    ----                       ------ -------
20170428.4 2017-04-28 15:07:42  succeeded michael@qedcode.com        3cb3bd Fixed build
20170428.3 2017-04-28 14:58:36  failed    michael@qedcode.com        6e6734 Open the rancor cage when button is hi...
20170428.2 2017-04-28 14:49:43  succeeded charles@qedcode.com        a3a97e Open the trap door when Jabba laughs.
20170428.1 2017-04-28 14:29:32  succeeded michael@qedcode.com        2b7d1c Force choke Gammorean guards.
20170427.12 2017-04-27 22:21:08 succeeded michael@qedcode.com        d7d690 Control entry droid with The Force.
20170427.11 2017-04-27 22:12:18 succeeded tim@qedcode.com            72e49e Project the hologram of the Jedi makin...
```

### Push-Build
Pushes a build to a target environment. Target environments are networks of virtual machines, either on-premises or in the cloud. They have been configured ahead of time in files named `config.dev.ps1`,  `config.test.ps1`,  `config.uat.ps1`, etc.

```
PS C:\MyProject\PuSH> .\Push-Build.ps1 test 20170428.4
```