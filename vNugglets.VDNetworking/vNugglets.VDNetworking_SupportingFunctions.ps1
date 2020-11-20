## some supporting functions used internally in the module

function Set-VNVDTrafficRuleset_helper {
<#	.Description
	Set the Rules property of the given Traffic Ruleset of a vDPortgroup traffic filter policy:  either add a rule, remove a rule, or overwrite the Rules altogether with the new rule(s) provided

	.Example
	Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oRule0, $oRule1 -RuleOperation Add -Enabled
	Add the two rules to the given TrafficRuleSet rules, and Enable the TrafficRuleSet

	.Example
	Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oSomeOldRule -RuleOperation Remove -Enabled:$false
	Remove this rule from the given TrafficRuleSet rules array, and Disable the TrafficRuleSet

	.Example
	Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oSomeTrafficRuleset -TrafficRule $oReplacementRule0, $oReplacementRule1 -RuleOperation Overwrite
	Set the rules array for the given TrafficRuleSet to have just these two rules

	.Outputs
	VNVDTrafficRuleSet
#>
	[CmdletBinding(DefaultParameterSetName="Default", SupportsShouldProcess=$true)]
	[OutputType([VNVDTrafficRuleSet])]
	param (
		## Given vDPortgroup's TrafficRuleset upon which to act
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VNVDTrafficRuleSet[]]$TrafficRuleSet,

		## TrafficRule(s) to use in upating the Rules property of the given TrafficRuleSet. If using -RuleOperation of "Remove", expects that this TrafficRule is fully populated with the Key property, too, as that is the "key" via which the existing rules are evaluated for removal
		[parameter(Mandatory=$true, ParameterSetName="ActOnRules")][VMware.Vim.DvsTrafficRule[]]$TrafficRule,

		## Operation to take on the TrafficRuleSet's Rules array with the given TrafficRule(s). "Add" the rule to the array, "Remove" the rule from the array, or "Overwrite" the array to be just the given rule(s)
		[parameter(Mandatory=$true, ParameterSetName="ActOnRules")][ValidateSet("Add", "Remove", "Overwrite")][String]$RuleOperation,

		## Switch:  enable the RuleSet? And, -Enabled:$false disables the Ruleset
		[Switch]$Enabled,

		## Switch:  Override the RuleSet? And, -Override:$false inherited the Ruleset
		[parameter(Mandatory=$true, ParameterSetName="Override")][Switch]$Override
	) ## end param

	process {
		$TrafficRuleSet | Foreach-Object {
			$oThisVNVDTrafficRuleset = $_
			$oVDPortgroupView_ThisTrafficRuleset = $oThisVNVDTrafficRuleset.VDPortgroupView
			$oVDPortView_ThisTrafficRuleset = $oThisVNVDTrafficRuleset.VDPortView
			if ($null -ne $oVDPortgroupView_ThisTrafficRuleset) {
				$strShouldProcessMsg_target = "Traffic Ruleset of key '{0}' on VDPortGroup '{1}'" -f $oThisVNVDTrafficRuleset.TrafficRuleset.Key, $oVDPortgroupView_ThisTrafficRuleset.Name
			} ## end if
			else {
				$strShouldProcessMsg_target = "Traffic Ruleset of key '{0}' on VDPort '{1}'" -f $oThisVNVDTrafficRuleset.TrafficRuleset.Key, $oVDPortView_ThisTrafficRuleset.Key
			} ## end else
			if ($PSCmdlet.ShouldProcess($strShouldProcessMsg_target)) {
				if ($null -ne $oVDPortgroupView_ThisTrafficRuleset) {
					## is there alraedy a configuration on a port?
					## then do not configure portgroup to prevent a destroyed config
					## (you can also destroy the congig without code in the WebUI...)
					$criteria = New-Object VMware.Vim.DistributedVirtualSwitchPortCriteria
					$criteria.PortgroupKey = New-Object String[] (1)
					$criteria.PortgroupKey[0] = $oVDPortgroupView_ThisTrafficRuleset.Key
					$criteria.Inside = $true
					$oVDSwitchView_ThisTrafficRuleset = Get-View -Id $oVDPortgroupView_ThisTrafficRuleset.Config.DistributedVirtualSwitch.ToString()
					$oVDPortViewWithOverride = $oVDSwitchView_ThisTrafficRuleset.FetchDVPorts($criteria) | Where-Object {$_.Config.Setting.FilterPolicy.FilterConfig.Inherited -eq $false} | Sort-Object Key
					$oVDPortViewWithOverrideKeys = $($oVDPortViewWithOverride.Key -join (','))
					if ($null -ne $oVDPortViewWithOverride) {
						Throw "Do not configure portgroup with already configured ports (PortKeys=$oVDPortViewWithOverrideKeys)."
					}

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
				} ## end if
				else {
					## update View data, to make sure we have the current info
					## UpdateViewData not exist on port, so we have to take the long way
					$oVDPort_ThisTrafficRuleset = Get-VDPort -VDPortgroup (Get-VDPortgroup -Id "DistributedVirtualPortgroup-$($oVDPortView_ThisTrafficRuleset.PortgroupKey)") -Key $oVDPortView_ThisTrafficRuleset.Key
					$oVDPortView_ThisTrafficRuleset = $oVDPort_ThisTrafficRuleset.ExtensionData

					## is there alraedy a configuration on a port?
					## then do not configure portgroup to prevent a destroyed config
					## (you can also destroy the congig without code in the WebUI...)
					if ($oVDPort_ThisTrafficRuleset.Portgroup.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Enabled -eq $true) { $bVPGCOnfig = $true }
					if ($null -ne $oVDPort_ThisTrafficRuleset.Portgroup.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig.TrafficRuleset.Rules) { $bVPGCOnfig = $true }
					if ($bVPGCOnfig) {
						Throw "Do not configure port with already configured portgroup."
					}

					## check if individual port config is allow
					if ($oVDPort_ThisTrafficRuleset.Portgroup.ExtensionData.Config.Policy.TrafficFilterOverrideAllowed -eq $false) {
						Throw "Config FilterPolicy of port is not allowed. Check Policy.TrafficFilterOverrideAllowed of portgroup."
					}


					## make a new config spec using values from the existing config of the vDPG
					$specDVPortConfigSpec = New-Object -Type VMware.Vim.DVPortConfigSpec -Property @{
						ConfigVersion     = $oVDPortView_ThisTrafficRuleset.Config.ConfigVersion
						Operation         = 'edit'
						key               = $oVDPortView_ThisTrafficRuleset.Key
						Setting           = New-Object -Type VMware.Vim.DVPortSetting -Property @{
							FilterPolicy = New-Object -Type VMware.Vim.DvsFilterPolicy -Property @{
								FilterConfig = New-Object -Type VMware.Vim.DvsTrafficFilterConfig -Property @{
									## if the current TrafficRuleset property is $null, create a new TrafficRuleset; else, use the existing TrafficRuleset
									# TrafficRuleset = if ($null -eq $oThisVNVDTrafficRuleset.TrafficRuleset -or $PSBoundParameters.ContainsKey("Override")) {New-Object -TypeName VMware.Vim.DvsTrafficRuleset} else {$oThisVNVDTrafficRuleset.TrafficRuleset}
									TrafficRuleset = if ($null -eq $oThisVNVDTrafficRuleset.TrafficRuleset) {New-Object -TypeName VMware.Vim.DvsTrafficRuleset} else {$oThisVNVDTrafficRuleset.TrafficRuleset}
									## use the current FilterConfig value for this property, and not setting the other properties
									AgentName      = if ($null -eq $oVDPortgroupView_ThisTrafficRuleset.Config.DefaultPortConfig.FilterPolicy.FilterConfig.AgentName) {"dvfilter-generic-vmware"} else {$oVDPortgroupView_ThisTrafficRuleset.Config.DefaultPortConfig.FilterPolicy.FilterConfig.AgentName}
									Key            = if ($null -eq $oVDPortView_ThisTrafficRuleset.Config.Setting.FilterPolicy.FilterConfig.Key) {""} else {$oVDPortView_ThisTrafficRuleset.Config.Setting.FilterPolicy.FilterConfig.Key}
								} ## end new-object
							} ## end new-object
						} ## end new-object
					} ## end new-object

					if ($PSBoundParameters.ContainsKey("Override")) {
						$specDVPortConfigSpec.Setting.FilterPolicy.Inherited = !$Override.ToBool()
					} ## end if


					if ($PSCmdlet.ParameterSetName -eq "ActOnRules") {
						Switch ($RuleOperation) {
							"Add" {
								## add the new TrafficRule to the RuleSet
								$specDVPortConfigSpec.Setting.FilterPolicy.FilterConfig.TrafficRuleset.Rules += $TrafficRule
								$bReturnUpdatedRulesetObject = $true
								break
							} ## end case
							"Remove" {
								## remove the TrafficRule(s) from the RuleSet
								$specDVPortConfigSpec.Setting.FilterPolicy.FilterConfig.TrafficRuleset.Rules = $specDVPortConfigSpec.Setting.FilterPolicy.FilterConfig.TrafficRuleset.Rules | Where-Object {$TrafficRule.Key -notcontains $_.Key}
								break
							} ## end case
							"Overwrite" {
								## overwrite the Rules Property in the RuleSet
								$specDVPortConfigSpec.Setting.FilterPolicy.FilterConfig.TrafficRuleset.Rules = $TrafficRule
								$bReturnUpdatedRulesetObject = $true
								break
							} ## end case
						} ## end switch
					} ## end if

					if ($PSBoundParameters.ContainsKey("Enabled")) {
						$specDVPortConfigSpec.Setting.FilterPolicy.FilterConfig.TrafficRuleset.Enabled = $Enabled.ToBool()
						if ($PSBoundParameters["RuleOperation"] -ne "Remove") {$bReturnUpdatedRulesetObject = $true}
					} ## end if

					if ($PSBoundParameters.ContainsKey("Override")) {
						$bReturnUpdatedRulesetObject = $true
					} ## end if

					## reconfig the VDPortgroup with the config spec
					$oVDPort_ThisTrafficRuleset.Switch.ExtensionData.ReconfigureDVPort($specDVPortConfigSpec)

					## get the current TrafficRuleSet and return it, if so specified (like, if add or overwrite of rules, but not for remove of a rule)
					if ($bReturnUpdatedRulesetObject) {$oVDPortView_ThisTrafficRuleset | Get-VNVDTrafficRuleSet}
				}
			} ## end if
		} ## end foreach-object
	} ## end process
} ## end function
