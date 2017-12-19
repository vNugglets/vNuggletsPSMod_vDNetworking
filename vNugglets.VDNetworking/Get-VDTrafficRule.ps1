<#	.Description
	Function to get the VDTrafficRule for the TrafficRuleset from the given VDTrafficFilterPolicy configuration from VDPortgroup(s).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VDTrafficFilterPolicyConfig.ps1 | Get-VDTrafficRule.ps1
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
