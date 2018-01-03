## some supporting functions used internally in the module

function _Set-VNVDTrafficRuleset_helper {
<#	.Description
	Set the Rules property of the given Traffic Ruleset of a vDPortgroup traffic filter policy:  either add a rule, remove a rule, or overwrite the Rules altogether with the new rule(s) provided

	.Example
	_Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oRule0, $oRule1 -RuleOperation Add -Enabled
	Add the two rules to the given TrafficRuleSet rules, and Enable the TrafficRuleSet

	.Example
	_Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oSomeOldRule -RuleOperation Remove -Enabled:$false
	Remove this rule from the given TrafficRuleSet rules array, and Disable the TrafficRuleSet

	.Example
	_Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oReplacementRule0, $oReplacementRule1 -RuleOperation Overwrite
	Set the rules array for the given TrafficRuleSet to have just these two rules

	.Outputs
	VNVDTrafficRuleSet
#>
	[CmdletBinding(DefaultParameterSetName="Default")]
	[OutputType([VNVDTrafficRuleSet])]
	param (
		## Given vDPortgroup's TrafficRuleset upon which to act
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VNVDTrafficRuleSet[]]$TrafficRuleSet,

		## TrafficRule(s) to use in upating the Rules property of the given TrafficRuleSet. If using -RuleOperation of "Remove", expects that this TrafficRule is fully populated with the Key property, too, as that is the "key" via which the existing rules are evaluated for removal
		[parameter(Mandatory=$true, ParameterSetName="ActOnRules")][VMware.Vim.DvsTrafficRule[]]$TrafficRule,

		## Operation to take on the TrafficRuleSet's Rules array with the given TrafficRule(s). "Add" the rule to the array, "Remove" the rule from the array, or "Overwrite" the array to be just the given rule(s)
		[parameter(Mandatory=$true, ParameterSetName="ActOnRules")][ValidateSet("Add", "Remove", "Overwrite")][String]$RuleOperation,

		## Switch:  enable the RuleSet? And, -Enabled:$false disables the Ruleset
		[Switch]$Enabled
	) ## end param

	process {
		$TrafficRuleSet | Foreach-Object {
			$oThisVNVDTrafficRuleset = $_
			$oVDPortgroupView_ThisTrafficRuleset = $oThisVNVDTrafficRuleset.VDPortgroupView
			## update View data, to make sure we have the current info
			$oVDPortgroupView_ThisTrafficRuleset.UpdateViewData("Config.ConfigVersion","Config.DefaultPortConfig.FilterPolicy.FilterConfig")

			## make a new config spec using values from the existing config of the vDPG
			$specDVPortgroupConfigSpec = New-Object -Type VMware.Vim.DVPortgroupConfigSpec -Property @{
				ConfigVersion = $oVDPortgroupView_ThisTrafficRuleset.Config.ConfigVersion
				DefaultPortConfig = New-Object -Type VMware.Vim.VMwareDVSPortSetting -Property @{
					FilterPolicy = New-Object -Type VMware.Vim.DvsFilterPolicy -Property @{
						FilterConfig = New-Object -Type VMware.Vim.DvsTrafficFilterConfig -Property @{
							## if the current TrafficRuleset property is $null, create a new TrafficRuleset; else, use the existing TrafficRuleset
							TrafficRuleset = if ($null -eq $oThisVNVDTrafficRuleset.TrafficRuleset) {New-Object -TypeName VMware.Vim.DvsTrafficRuleset} else {$oThisVNVDTrafficRuleset.TrafficRuleset}
							## use the current FilterConfig value for this property, and not setting the other properties
							AgentName = if ($null -eq $oVDPortgroupView_ThisTrafficRuleset.Config.DefaultPortConfig.FilterPolicy.FilterConfig.AgentName) {"dvfilter-generic-vmware"} else {$oVDPortgroupView_ThisTrafficRuleset.Config.DefaultPortConfig.FilterPolicy.FilterConfig.AgentName}
						} ## end new-object
					} ## end new-object
				} ## end new-object
			} ## end new-object

			if ($PSCmdlet.ParameterSetName -eq "ActOnRules") {
				Switch ($RuleOperation) {
					"Add" {
						## add the new TrafficRule to the RuleSet
						$specDVPortgroupConfigSpec.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Rules += $TrafficRule
						$bReturnUpdatedRulesetObject = $true
						break
					} ## end case
					"Remove" {
						## remove the TrafficRule(s) from the RuleSet
						$specDVPortgroupConfigSpec.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Rules = $specDVPortgroupConfigSpec.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Rules | Where-Object {$TrafficRule.Key -notcontains	$_.Key}
						break
					} ## end case
					"Overwrite" {
						## overwrite the Rules Property in the RuleSet
						$specDVPortgroupConfigSpec.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Rules = $TrafficRule
						$bReturnUpdatedRulesetObject = $true
						break
					} ## end case
				} ## end switch
			} ## end if

			if ($PSBoundParameters.ContainsKey("Enabled")) {
				$specDVPortgroupConfigSpec.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Enabled = $Enabled.ToBool()
				if ($PSBoundParameters["RuleOperation"] -ne "Remove") {$bReturnUpdatedRulesetObject = $true}
			} ## end if

			## reconfig the VDPortgroup with the config spec
			$oVDPortgroupView_ThisTrafficRuleset.ReconfigureDVPortgroup($specDVPortgroupConfigSpec)

			## get the current TrafficRuleSet and return it, if so specified (like, if add or overwrite of rules, but not for remove of a rule)
			if ($bReturnUpdatedRulesetObject) {$oVDPortgroupView_ThisTrafficRuleset | Get-VNVDTrafficRuleSet}
		} ## end foreach-object
	} ## end process
} ## end function
