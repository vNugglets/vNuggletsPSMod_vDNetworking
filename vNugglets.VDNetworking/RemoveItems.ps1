function Remove-VNVDTrafficRule {
<#	.Description
	Remove a Traffic Rule from the given Traffic Ruleset of a vDPortgroup traffic filter policy

	.Notes
	Operating with the understanding/observation that there is only ever one (1) Config.DefaultPortConfig.FilterPolicy.FilterConfig per vDPortgroup (and, so, one subsequent TrafficRuleset, since a FilterConfig has one TrafficRuleset), even though the .FilterConfig property is of type VMware.Vim.DvsFilterConfig[] (an array)
	This is based on testing to try to make a vDPortgroup with more than one FilterConfig, and only ever having a maximum of one

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule -Name test* | Remove-VNVDTrafficRule
	Get the TrafficRules named like "test*" from the TrafficRuleSet for the given vDPortGroup and delete them.

	.Outputs
	Null. Removes rule(s) as directed, returning nothing upon success.
#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
	param (
		## The traffic ruleset rule(s) to remove from the traffic filter policy of associated virtual distributed portgroup
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficRule")][VNVDTrafficRule[]]$TrafficRule
	) ## end param

	begin {
		## arraylist to hold all of the TrafficRules to be removed (in one swell foop, since each upate/reconfig of the vDPortgroup results in new keys for the rule objects)
		$arrlVNVDTrafficRulesToRemove = New-Object -TypeName System.Collections.ArrayList
	} ## end begin

	process {
		## put each TrafficRule into the arraylist for later action (one reconfig per vDPortgroup)
		$TrafficRule | Foreach-Object {$arrlVNVDTrafficRulesToRemove.Add($_) | Out-Null}
	} ## end process

	end {
		## Group the TrafficRules by vDPortgroup (by grouping by MoRef per vCenter), then reconfig each vDPortgroup to remove the given Rule(s) for that vDPortgroup's sole TrafficRuleset all at once
		$arrlVNVDTrafficRulesToRemove | Group-Object -Property @{e={$_.VDPortgroupView.MoRef}}, @{e={$_.VDPortgroupView.Client.ServiceUrl}} | Foreach-Object {
			$oThisPSGroupInfoOfTrafficRules = $_
			# The vDPortgroup with these TrafficRules (used in logging/reporting)
			$oVDPG_TheseRules = $oThisPSGroupInfoOfTrafficRules.Group[0].VDPortgroupView
			# The VNVDTrafficRuleSet for these TrafficRules, to be used to remove the given TrafficRule(s)
			$oVNVDTrafficRuleset_TheseRules = $oThisPSGroupInfoOfTrafficRules.Group[0].VNVDTrafficRuleSet
			## the VMware.Vim.DvsTrafficRule objects to remove from the given TrafficRuleset
			$arrDvsTrafficRulesToRemove = $oThisPSGroupInfoOfTrafficRules.Group.TrafficRule

			$strMsgForShouldProcess_Target = "Traffic ruleset '{0}' on vDPortgroup '{1}'" -f $oVNVDTrafficRuleset_TheseRules.TrafficRuleset.Key, $oVDPG_TheseRules.Name
			$intNumDvsTrafficRulesToRemove = ($arrDvsTrafficRulesToRemove | Measure-Object).Count
			$strMsgForShouldProcess_Action = "Remove {0} traffic rule{1} (of name{1} '{2}')" -f $intNumDvsTrafficRulesToRemove, $(if ($intNumDvsTrafficRulesToRemove -ne 1) {"s"}), ($arrDvsTrafficRulesToRemove.Description -join ", ")
			if ($PSCmdlet.ShouldProcess($strMsgForShouldProcess_Target, $strMsgForShouldProcess_Action)) {
				try {
					## use the helper function to remove this TrafficRule from the TrafficRuleSet Rules array
					$oUpdatedTrafficRuleset = _Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oVNVDTrafficRuleset_TheseRules -TrafficRule $arrDvsTrafficRulesToRemove -RuleOperation Remove
				} ## end try
				catch {Throw $_}
			} ## end if
		} ## end foreach-object
	} ## end end
} ## end fn
