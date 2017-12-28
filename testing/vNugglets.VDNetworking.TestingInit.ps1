<#	.Description
	Initialization code for use by multiple *.Tests.ps1 files for testing vNugglets.vDNetworking PowerShell module
#>
param (
	## Name of the vCenter virtual Datacenter to use in the vNugglets.vDNetworking testing
	[parameter(Mandatory=$true)][string]$Datacenter
)

$strThisModuleName = "vNugglets.vDNetworking"
## if module not already loaded, try to load it (assumes that module is in PSModulePath)
if (-not ($oModuleInfo = Get-Module $strThisModuleName)) {
	$oModuleInfo = Import-Module $strThisModuleName -PassThru
	if (-not ($oModuleInfo -is [System.Management.Automation.PSModuleInfo])) {Throw "Could not load module '$strThisModuleName' -- is it available in the PSModulePath? You can manually load the module and start tests again"}
} ## end if
Write-Verbose -Verbose ("Starting testing of module '{0}' (version '{1}' from '{2}')" -f $oModuleInfo.Name, $oModuleInfo.Version, $oModuleInfo.Path)

## get the VIServer connection to use
$oVIServerConnectionToUse = if (-not (($global:DefaultVIServers | Measure-Object).Count -gt 0)) {
	$hshParamForConnectVIServer = @{Server = $(Read-Host -Prompt "vCenter server to which to connect for testing")}
	Connect-VIServer @hshParamForConnectVIServer
} ## end if
else {$global:DefaultVIServers[0]}
Write-Verbose -Verbose "Testing using VIServer of name '$($oVIServerConnectionToUse.Name)'"


## get the datacenter use for testing
$oVDatacenterToUse = Get-Datacenter -Name $Datacenter | Select-Object -First 1
Write-Verbose -Verbose "Testing using virtual datacenter '$oVDatacenterToUse'"

return $oVDatacenterToUse