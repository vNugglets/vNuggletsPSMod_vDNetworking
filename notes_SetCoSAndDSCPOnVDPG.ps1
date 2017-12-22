## Sample code to set Class of Service (CoS) and Differentiated Service Code Point (DSCP) TrafficRules to TrafficFilterConfig TrafficRuleSet on vDPGs on a VDSwitch

Need:
- Remove-VNVDTrafficRule -Rule -RunAsync
    - set confirmation level to High
    - removes a given rule from the ruleset on the given VDPG
- Set-VNVDTrafficRuleSet -Enabled -Rule -Precedence -VDPortgroup|-TrafficRuleset
    - set confirmation level to High
    - enables the overwriting of the rules in the ruleset with jsut the new Rule(s) specified
- Get-VNVDTrafficRuleAction

Maybe eventually add:
- Copy-VNVDTrafficRule -Rule -Ruleset rulesettowhichtocopy
- Set-VNVDTrafficRule -- to update a rule, maybe? (like change qualifier/action?)
- New-VNVDTrafficRule
    - may need to add logic to ensure it meets requirement stated in API ref of, "There can be a maximum of 1 DvsIpNetworkRuleQualifier, 1 DvsMacNetworkRuleQualifier and 1 DvsSystemTrafficNetworkRuleQualifier for a total of 3 qualifiers"

Done (to at least some extent -- some may have further features to implement):
- Get-VNVDTrafficFilterPolicyConfig
- Get-VNVDTrafficRuleSet (returns VNVDTrafficRuleSet object with VDPG property, too)
- Get-VNVDTrafficRule
- Get-VNVDTrafficRuleQualifier
- New-VNVDTrafficRuleQualifier
- New-VNVDTrafficRuleAction
    - remaining Action types to implement: DvsCopyNetworkRuleAction, DvsGreEncapNetworkRuleAction, DvsLogNetworkRuleAction, DvsMacRewriteNetworkRuleAction, DvsPuntNetworkRuleAction, DvsRateLimitNetworkRuleAction
- Ruleset object returned from Get-VNVDTrafficRuleSet  should have property of "parent vDPG", to be used for vDPG reconfig task (need to add vDPG property to return from Get-VNVDTrafficFilterPolicyConfig, Get-VNVDTrafficRuleSet, and Get-VNVDTrafficRule)
- New-VNVDTrafficRule
    - adds rule to TrafficRuleset

## something like
#  gets
# get-vdpg | get-vdtrafficruleset | add-vdtrafficrule
# get-vdpg | get-vdtrafficruleset | get-vdtrafficrule
#  new
# $oTraffQualifier0 = New-VNVDTrafficRuleQualifier -ParmsHere
# $oTraffQualifier1 = New-VNVDTrafficRuleQualifier -ParmsHere
# $oTraffRule = New-VNVDTrafficRule -Direction blahh -Qualifier $oTraffQualifier0, $oTraffQualifier1
# get-vdpg someVdpg | New-VNVDTrafficPolicy -Enabled -Rule $oTraffRule
# or
#  overwrite all rules in the ruleset (if any) with new rule(s) specified
# get-vdpg someVdpg | Get-VNVdpgTrafficRuleSet | Set-VNVdpgTrafficRuleSet -Enabled -Rule (New-VNVDTrafficRule -Direction blahh -Qualifier (New-VNVDTrafficRuleQualifier -ParmsHere))
#  add traffic rule to traffic ruleset
# get-vdpg someVdpg | Get-VNVdpgTrafficRuleSet | Add-VNVdpgTrafficRuleSetRule -Rule (New-VNVDTrafficRule -Direction blahh -Qualifier (New-VNVDTrafficRuleQualifier -ParmsHere))


<# example from https://communities.vmware.com/thread/493610?q=distributed%20switch%20traffic%20filter
$dvSwName = 'dvSw1'
$dvPgNames = 'dvPg1'

$dvSw = Get-VDSwitch -Name $dvSwName

foreach($pg in (Get-View -Id  $dvSw.ExtensionData.Portgroup | Where {$dvPgNames -contains $_.Name})){
    $spec = New-Object VMware.Vim.DVPortgroupConfigSpec
    $spec.ConfigVersion = $pg.Config.ConfigVersion
    $spec.DefaultPortConfig = New-Object VMware.Vim.VMwareDVSPortSetting
    $spec.DefaultPortConfig.FilterPolicy = New-Object VMware.Vim.DvsFilterPolicy

    $filter = New-Object VMware.Vim.DvsTrafficFilterConfig
    $filter.AgentName = 'dvfilter-generic-vmware'

    $ruleSet = New-Object VMware.Vim.DvsTrafficRuleset
    $ruleSet.Enabled = $true

    $rule =New-Object VMware.Vim.DvsTrafficRule
    $rule.Description = 'Traffic Rule Name'
    $rule.Direction = 'outgoingPackets'

    $action = New-Object VMware.Vim.DvsUpdateTagNetworkRuleAction
    $action.QosTag = 4

    $rule.Action += $action

    $ruleSet.Rules += $rule

    $filter.TrafficRuleSet += $ruleSet

    $spec.DefaultPortConfig.FilterPolicy.FilterConfig += $filter

    $pg.ReconfigureDVPortgroup($spec)
}
#>


## get VDTrafficFilterPolicyConfig:
#$viewVDPG.Config.DefaultPortConfig.FilterPolicy.FilterConfig
## can get:
# VDTrafficFilterPolicyConfig:  Key, Enabled, Precedence, Key, AgentName, SlotNumber, Parameters, OnFailure, Inherited
# --> VDTrafficFilterPolicyConfig.VDTrafficRule: Key, Description, Sequence, Qualifier, Action, Direction
# --> VDTrafficFilterPolicyConfig.VDTrafficRule.VDTrafficRuleQualifier:  VMware.Vim.DvsSystemTrafficNetworkRuleQualifier or VMware.Vim.DvsIpNetworkRuleQualifier or one other
