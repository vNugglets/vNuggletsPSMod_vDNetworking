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
	$strModuleFolderFilespec = "$PSScriptRoot\$strModuleName"
	$strFilespecForPsd1 = Join-Path $strModuleFolderFilespec "${strModuleName}.psd1"

	## parameters for use by both New-ModuleManifest and Update-ModuleManifest
	$hshManifestParams = @{
		# Confirm = $true
		Path = $strFilespecForPsd1
		ModuleVersion = "1.2.0"
		Author = "Matt Boren (@mtboren)"
		CompanyName = 'vNugglets for the VMware PowerCLI community'
		Copyright = "MIT License"
		Description = "Module with functions for managing VMware vSphere Virtual Distributed Networking components like traffic filtering and marking, and vDUplink <--> VMNIC management"
		# AliasesToExport = @()
		FileList = Write-Output "${strModuleName}.psd1" "${strModuleName}_ModRoot.psm1" "en-US\about_${strModuleName}.help.txt" GetItems.ps1 NewItems.ps1 RemoveItems.ps1 SetItems.ps1 "${strModuleName}_SupportingFunctions.ps1" "${strModuleName}.format.ps1xml" "${strModuleName}_init.ps1" "${strModuleName}_ClassDefinition.ps1"
		FormatsToProcess = "${strModuleName}.format.ps1xml"
		FunctionsToExport = Write-Output Get-VNVDTrafficFilterPolicyConfig Get-VNVDTrafficRuleSet Get-VNVDTrafficRule Get-VNVDTrafficRuleQualifier Get-VNVDTrafficRuleAction Get-VNVSwitchByVMHostNetworkAdapter New-VNVDTrafficRuleQualifier New-VNVDTrafficRuleAction New-VNVDTrafficRule Remove-VNVDTrafficRule Set-VNVDTrafficRuleSet Set-VNVMHostNetworkAdapterVDUplink
		IconUri = "https://avatars0.githubusercontent.com/u/10615837"
		LicenseUri = "https://github.com/vNugglets/vNuggletsPSMod_vDNetworking/blob/master/License"
		NestedModules = Write-Output GetItems.ps1 NewItems.ps1 RemoveItems.ps1 SetItems.ps1 "${strModuleName}_SupportingFunctions.ps1"
		PowerShellVersion = [System.Version]"5.0"
		ProjectUri = "https://github.com/vNugglets/vNuggletsPSMod_vDNetworking"
		ReleaseNotes = "See ReadMe and other docs at https://github.com/vNugglets/vNuggletsPSMod_vDNetworking"
		RequiredModules = "VMware.VimAutomation.Vds"
		RootModule = "${strModuleName}_ModRoot.psm1"
		ScriptsToProcess = "${strModuleName}_init.ps1", "${strModuleName}_ClassDefinition.ps1"
		Tags = Write-Output vNugglets VMware vSphere PowerCLI VDPortGroup VDPort TrafficFiltering Filter Filtering TrafficMarking Mark Marking VDSwitch Uplink VDUplink VMHostNetworkAdapater VMNIC
		# Verbose = $true
	} ## end hashtable

	# $hshUpdateManifestParams = @{
	# 	## modules that are external to this module and that this module requires; per help, "Specifies an array of external module dependencies"
	# 	ExternalModuleDependencies = VMware.VimAutomation.Vds
	# }
} ## end begin

process {
	$bManifestFileAlreadyExists = Test-Path $strFilespecForPsd1
	## check that the FileList property holds the names of all of the files in the module directory, relative to the module directory
	## the relative names of the files in the module directory (just filename for those in module directory, "subdir\filename.txt" for a file in a subdir, etc.)
	$arrRelativeNameOfFilesInModuleDirectory = Get-ChildItem $strModuleFolderFilespec -Recurse | Where-Object {-not $_.PSIsContainer} | ForEach-Object {$_.FullName.Replace($strModuleFolderFilespec, "").TrimStart("\")}
	if ($null -eq (Compare-Object -ReferenceObject $hshManifestParams.FileList -DifferenceObject $arrRelativeNameOfFilesInModuleDirectory)) {Write-Verbose -Verbose "Hurray, all of the files in the module directory are named in the FileList property to use for the module manifest"} else {Write-Error "Uh-oh -- FileList property value for making/updating module manifest and actual files present in module directory do not match. Better check that."}
	$strMsgForShouldProcess = "{0} module manifest" -f $(if ((-not $bManifestFileAlreadyExists) -or $Recreate) {"Create"} else {"Update"})
	if ($PsCmdlet.ShouldProcess($strFilespecForPsd1, $strMsgForShouldProcess)) {
		## do the actual module manifest creation/update
		if ((-not $bManifestFileAlreadyExists) -or $Recreate) {Microsoft.PowerShell.Core\New-ModuleManifest @hshManifestParams}
		else {PowerShellGet\Update-ModuleManifest @hshManifestParams}
		## replace the comment in the resulting module manifest that includes "PSGet_" prefixed to the actual module name with a line without "PSGet_" in it
		(Get-Content -Path $strFilespecForPsd1 -Raw).Replace("# Module manifest for module 'PSGet_$strModuleName'", "# Module manifest for module '$strModuleName'") | Set-Content -Path $strFilespecForPsd1
	} ## end if
} ## end process
