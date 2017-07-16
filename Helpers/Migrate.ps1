[CmdletBinding()]
param(
	[Parameter(Mandatory=$true)]
	[string] $ConnectionString
)

$MigrateExe = Join-Path $PSScriptRoot "migrate.exe"

& $MigrateExe @( "Your.Migration.Assembly.dll", "/startupDirectory=`"$PSScriptRoot`"", "/connectionString=`"$ConnectionString`"", "/connectionProviderName=`"System.Data.SqlClient`"" )