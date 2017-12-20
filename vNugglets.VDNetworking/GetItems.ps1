function Get-VNVDTrafficFilterPolicyConfig {
<#	.Description
	Function to get the VDTrafficFilterPolicy configuration for the given VDPortgroup(s) from VDSwitch(es).  The VDTrafficFilterPolicy is the item that can be enabled/disabled at the vDPG level.

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig

	.Outputs
	VMware.Vim.DvsTrafficFilterConfig
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficFilterConfig])]
	param (
		## The virtual distributed portgroup for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup
	) ## end param

	process {
		$VDPortgroup | Foreach-Object {
			$_.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig
		} ## end foreach-object
	} ## end process
} ## end fn



function Get-VNVDTrafficRuleSet {
<#	.Description
	Function to get the DvsTrafficRuleset for the given VDTrafficFilterPolicy configuration from VDPortgroup(s), or from VDPortgroup(s) directly.

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet
	Get the traffic ruleset from the TrafficFilterPolicyConfig object of a given vDPG. Can also get the ruleset from just the vDPG, but this "from TrafficFilterPolicyConfig" method is to help show the relationship between the vDPG, the TrafficFilterPolicyConfig, and the TrafficRuleset

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet
	Get the traffic ruleset directly from the given vDPG

	.Outputs
	VMware.Vim.DvsTrafficRuleset
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficRuleset])]
	param (
		## The traffic filter policy config of the virtual distributed portgroup for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficFilterPolicyConfig")][VMware.Vim.DvsTrafficFilterConfig[]]$TrafficFilterPolicyConfig,

		## The virtual distributed portgroup for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByVDPortGroup")][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup
	) ## end param

	process {
		Switch ($PSCmdlet.ParameterSetName) {
			"ByTrafficFilterPolicyConfig" {
				$TrafficFilterPolicyConfig | Foreach-Object {$_.TrafficRuleset}
				break
			} ## end case

			"ByVDPortGroup" {
				$VDPortgroup | Foreach-Object {$_.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset}
			} ## end case
		} ## end switch
	} ## end process
} ## end function



function Get-VNVDTrafficRule {
<#	.Description
	Function to get the VDTrafficRule for the TrafficRuleset from the given VDTrafficFilterPolicy configuration from VDPortgroup(s).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
	Get the traffic rules from the TrafficeRuleset, which was gotten from the vDPG's TrafficFilterPolicyConfig

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule -Name traffic*
	Get traffic rules whose name is like "traffic*".

	.Outputs
	VMware.Vim.DvsTrafficRule
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficRule])]
	param (
		## The name(s) of the Traffic Rule(s) to return (accepts wildcards). If -Name or -LiteralName not specified, will return all Traffic Rules for the given traffic rule set
		[String[]]$Name,

		## The name(s) of the Traffic Rule(s) to return (exact match only, no wildcarding employed). If -Name or -LiteralName not specified, will return all Traffic Rules for the given traffic rule set
		[String[]]$LiteralName,

		## The traffic ruleset from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule(s)
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficRuleset")][VMware.Vim.DvsTrafficRuleset[]]$TrafficRuleset
	) ## end param

	process {
		$TrafficRuleset | Foreach-Object {
			## if -Name was passed, only return rules whose descriptions are like the given name value(s)
			if ($PSBoundParameters.ContainsKey("Name")) {$_.Rules | Where-Object {$oThisDescription = $_.Description; ($Name | Foreach-Object {$oThisDescription -like $_}) -contains $true}}
			elseif ($PSBoundParameters.ContainsKey("LiteralName")) {$_.Rules | Where-Object {$LiteralName -contains $_.Description}}
			else {$_.Rules}
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
		[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="ByTrafficRuleQualifier")][AllowNull()][VMware.Vim.DvsNetworkRuleQualifier[]]$Qualifier
	) ## end param

	process {
		## if there were any qualifier objects passed in that were _not_ $null
		if (($Qualifier | Where-Object {$null -ne $_} | Measure-Object).Count -gt 0) {
			$Qualifier | Foreach-Object {
				## get the qualifier TypeName short name (like, if TypeName is "VMware.Vim.DvsIpNetworkRuleQualifier", this will be "DvsIpNetworkRuleQualifier")
				$strQualifierTypeShortname = ($_ | Get-Member | Select-Object -First 1).TypeName.Split(".") | Select-Object -Last 1
				## the properties to select for this Qualifier object
				$arrPropertyForSelectObject = @{n="QualifierType"; e={$strQualifierTypeShortname}}, "*"
				## if the Qualifier object is of type VMware.Vim.DvsSystemTrafficNetworkRuleQualifier, essentially "expand" the TypeOfSystemTraffic.Value property to be one level up in the return object
				if ($strQualifierTypeShortname -eq "DvsSystemTrafficNetworkRuleQualifier") {$arrPropertyForSelectObject += @{n="TypeOfSystemTraffic_Name"; e={$_.TypeOfSystemTraffic.Value}}}
				$_ | Select-Object -Property $arrPropertyForSelectObject
			} ## end foreach-object
		} ## end if
		else {Write-Verbose "Null value passed for Qualifier parameter.  Possibility:  input object's Qualifier property is `$null (which is perfectly feasible/acceptable for a traffic rule)"}
	} ## end process
} ## end function
