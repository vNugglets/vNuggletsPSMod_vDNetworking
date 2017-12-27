<#	.Description
	Some code to help automate the updating of the ModuleManifest file (will create it if it does not yet exist, too)
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
	## Recreate the manifest (overwrite with full, fresh copy instead of update?)
	[Switch]$Recreate
)
begin {
	$strModuleName = "vNugglets.VDNetworking"
	## some code to generate the module manifest
	$strFilespecForPsd1 = "$PSScriptRoot\$strModuleName\${strModuleName}.psd1"

	$hshModManifestParams = @{
		# Confirm = $true
		Path = $strFilespecForPsd1
		ModuleVersion = "0.5.0"
		CompanyName = 'vNugglets for the VMware PowerCLI community'
		Copyright = "MIT License"
		Description = "Module with functions for managing VMware vSphere Virtual Distributed Networking components like traffic filtering and marking"
		# AliasesToExport = @()
		FileList = Write-Output "${strModuleName}.psd1" "${strModuleName}_ModRoot.psm1" "en-US\about_${strModuleName}.help.txt" GetItems.ps1 NewItems.ps1 RemoveItems.ps1 "${strModuleName}_SupportingFunctions.ps1" "${strModuleName}.format.ps1xml"
		FormatsToProcess = "${strModuleName}.format.ps1xml"
		FunctionsToExport = Write-Output Get-VNVDTrafficFilterPolicyConfig Get-VNVDTrafficRuleSet Get-VNVDTrafficRule Get-VNVDTrafficRuleQualifier New-VNVDTrafficRuleQualifier New-VNVDTrafficRuleAction New-VNVDTrafficRule Remove-VNVDTrafficRule
		IconUri = "https://avatars0.githubusercontent.com/u/10615837"
		LicenseUri = "https://github.com/vNugglets/vNuggletsPSMod_vDNetworking/blob/master/License"
		NestedModules = Write-Output GetItems.ps1 NewItems.ps1 RemoveItems.ps1 "${strModuleName}_SupportingFunctions.ps1"
		PowerShellVersion = [System.Version]"5.0"
		ProjectUri = "https://github.com/vNugglets/vNuggletsPSMod_vDNetworking"
		ReleaseNotes = "See release notes at https://github.com/vNugglets/vNuggletsPSMod_vDNetworking/blob/master/ChangeLog.md"
		RootModule = "${strModuleName}_ModRoot.psm1"
		ScriptsToProcess = "${strModuleName}_ClassDefinition.ps1"
		Tags = Write-Output vNugglets VMware vSphere PowerCLI VDPortGroup TrafficFiltering Filter Filtering TrafficMarking Mark Marking VDSwitch
		# Verbose = $true
	} ## end hashtable
} ## end begin

process {
	$bManifestFileAlreadyExists = Test-Path $strFilespecForPsd1
	$strMsgForShouldProcess = "{0} module manifest" -f $(if ((-not $bManifestFileAlreadyExists) -or $Recreate) {"Create"} else {"Update"})
	if ($PsCmdlet.ShouldProcess($strFilespecForPsd1, $strMsgForShouldProcess)) {
		## do the actual module manifest creation/update
		if ((-not $bManifestFileAlreadyExists) -or $Recreate) {Microsoft.PowerShell.Core\New-ModuleManifest @hshModManifestParams}
		else {PowerShellGet\Update-ModuleManifest @hshModManifestParams}
		## replace the comment in the resulting module manifest that includes "PSGet_" prefixed to the actual module name with a line without "PSGet_" in it
		(Get-Content -Path $strFilespecForPsd1 -Raw).Replace("# Module manifest for module 'PSGet_$strModuleName'", "# Module manifest for module '$strModuleName'") | Set-Content -Path $strFilespecForPsd1
	} ## end if
} ## end prcoess
