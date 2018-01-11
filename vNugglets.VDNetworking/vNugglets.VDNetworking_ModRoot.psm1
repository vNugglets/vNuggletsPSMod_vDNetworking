## remove the "psuedo" modules that get created at overall Module import time as they are in ScriptToProcess section of manifest; removing these psuedo modules seems to have no ill effect on the initialization and class definitions in the PowerShell session
Write-Output vNugglets.VDNetworking_init, vNugglets.VDNetworking_ClassDefinition | Foreach-Object {if (Get-Module -Name $_ -ErrorAction:SilentlyContinue) {Remove-Module -Name $_}}
