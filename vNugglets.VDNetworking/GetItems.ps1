function Get-VNVDTrafficFilterPolicyConfig {
<#	.Description
	Function to get the VDTrafficFilterPolicy configuration for the given VDPortgroup(s) from VDSwitch(es).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig

	.Outputs
	Selected.VMware.Vim.DvsTrafficFilterConfig
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficFilterConfig])]
	param (
		## The virtual distributed portgroup for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup
	) ## end param

	process {
		$VDPortgroup | Foreach-Object {
			$_.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig | Select-Object -Property *, @{n="Enabled"; e={$_.TrafficRuleset.Enabled}}
		} ## end foreach-object
	} ## end process
} ## end fn



function Get-VNVDTrafficRule {
<#	.Description
	Function to get the VDTrafficRule for the TrafficRuleset from the given VDTrafficFilterPolicy configuration from VDPortgroup(s).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule
	Get the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig

	.Outputs
	Selected.VMware.Vim.DvsTrafficRule
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficRule])]
	param (
		## The traffic ruleset from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule(s)
		[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="ByTrafficRuleset")][VMware.Vim.DvsTrafficRuleset[]]$TrafficRuleset
	) ## end param

	process {
		$TrafficRuleset | Foreach-Object {
			$oThisDvsTrafficRuleset = $_
			## if there are any Rules defined, return them
			if ($null -ne $oThisDvsTrafficRuleset.Rules) {$oThisDvsTrafficRuleset.Rules | Select-Object -Property *, @{n="ActionQosTag"; e={$_.Action.QosTag}}, @{n="ActionDscpTag"; e={$_.Action.DscpTag}}}
		} ## end foreach-object
	} ## end process
} ## end function



function Get-VNVDTrafficRuleQualifier {
<#	.Description
	Function to get the VDTrafficRule Qualifier for the TrafficRule from the given VDTrafficFilterPolicy configuration from VDPortgroup(s).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule | Get-VNVDTrafficRuleQualifier
	Get the traffic rules qualifiers from the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig

	.Outputs
	VMware.Vim.DvsNetworkRuleQualifier
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsNetworkRuleQualifier])]
	param (
		## The traffic ruleset qualifier from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule(s)
		[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="ByTrafficRuleQualifier")][VMware.Vim.DvsNetworkRuleQualifier[]]$Qualifier
	) ## end param

	process {
		$Qualifier | Foreach-Object {
			## get the qualifier TypeName short name (like, if TypeName is "VMware.Vim.DvsIpNetworkRuleQualifier", this will be "DvsIpNetworkRuleQualifier")
			$strQualifierTypeShortname = ($_ | Get-Member | Select-Object -First 1).TypeName.Split(".") | Select-Object -Last 1
			## the properties to select for this Qualifier object
			$arrPropertyForSelectObject = @{n="QualifierType"; e={$strQualifierTypeShortname}}, "*"
			## if the Qualifier object is of type VMware.Vim.DvsSystemTrafficNetworkRuleQualifier, essentially "expand" the TypeOfSystemTraffic.Value property to be one level up in the return object
			if ($strQualifierTypeShortname -eq "DvsSystemTrafficNetworkRuleQualifier") {$arrPropertyForSelectObject += @{n="TypeOfSystemTraffic_Name"; e={$_.TypeOfSystemTraffic.Value}}}
			$_ | Select-Object -Property $arrPropertyForSelectObject
		} ## end foreach-object
	} ## end process
} ## end function
