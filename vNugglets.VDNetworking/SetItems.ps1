function Set-VNVDTrafficRuleSet {
<#	.Description
	Set attributes on the DvsTrafficRuleset (like Enable/Disable it) for the given TrafficRuleSet

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled
	Get the traffic ruleset from the TrafficFilterPolicyConfig object of a given vDPG and Enable it

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled:$false
	Get the traffic ruleset from the given vDPG and Disable it

	.Outputs
	VNVDTrafficRuleSet with properties with at least VMware.Vim.DvsTrafficRuleset and VMware.Vim.DistributedVirtualPortgroup for the Traffic rule set
#>
	[CmdletBinding(ConfirmImpact="High", SupportsShouldProcess=$true)]
	[OutputType([VNVDTrafficRuleSet])]
	param (
		## Given vDPortgroup's TrafficRuleset upon which to act
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VNVDTrafficRuleSet[]]$TrafficRuleSet,

		## Switch: Enable the TrafficRuleSet(s)?  And, use "-Enabled:$false" to disable TrafficRuleSet(s)
		[Switch]$Enabled
	) ## end param

	process {
		$TrafficRuleSet | Foreach-Object {
			$oThisVNVDTrafficRuleset = $_
			$strMsgForShouldProcess_Target = "Traffic ruleset '{0}' on vDPG '{1}'" -f $oThisVNVDTrafficRuleset.TrafficRuleset.Key, $oThisVNVDTrafficRuleset.VDPortgroupView.Name
			$strMsgForShouldProcess_Action = "{0} ruleset" -f $(if ($Enabled) {"Enable"} else {"Disable"})
			if ($PSCmdlet.ShouldProcess($strMsgForShouldProcess_Target, $strMsgForShouldProcess_Action)) {
				try {
					## use the helper function to add this new TrafficRule to the TrafficRuleSet Rules array
					Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oThisVNVDTrafficRuleset -Enabled:$Enabled
				} ## end try
				catch {Throw $_}
			} ## end if
		} ## end foreach-object
	} ## end process
} ## end function
