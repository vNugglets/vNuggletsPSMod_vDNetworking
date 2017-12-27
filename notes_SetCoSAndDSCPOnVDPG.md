## Notes on Traffic Filtering and Marking code


### Need to make:
- `Get-VNVDTrafficRuleAction`
- `Set-VNVDTrafficRuleSet -Enabled -Precedence -TrafficRuleset`
    - define cmdlet `ConfirmImpact` to High
- Examples/docs
- Tests

### Maybe eventually add:
- `Copy-VNVDTrafficRule -Rule -Ruleset <rulesettowhichtocopy>`
- `Set-VNVDTrafficRule` -- to update a rule, maybe? (like change qualifier/action?)
- `New-VNVDTrafficRule`
    - may need to add logic to ensure it meets requirement stated in API ref of, "There can be a maximum of 1 DvsIpNetworkRuleQualifier, 1 DvsMacNetworkRuleQualifier, and 1 DvsSystemTrafficNetworkRuleQualifier for a total of 3 qualifiers"
- `Set-VNVDTrafficRuleSet -Enabled -Precedence -Rule -TrafficRuleset`
    - to enable/disable the Ruleset, and maybe to allow for the overwriting of the rules in the ruleset with just the new Rule(s) specified
- add `-RunAsync` to `New-VNVDTrafficRule`, `Remove-VNVDTrafficRule`, and any other cmdlet where it makes sense

Done (to at least some extent -- some may have further features to implement):
- `Get-VNVDTrafficFilterPolicyConfig`
- `Get-VNVDTrafficRuleSet` (returns VNVDTrafficRuleSet object with VDPG property, too)
- `Get-VNVDTrafficRule`
- `Get-VNVDTrafficRuleQualifier`
- `New-VNVDTrafficRuleQualifier`
- `New-VNVDTrafficRuleAction`
    - remaining Action types to implement: DvsCopyNetworkRuleAction, DvsGreEncapNetworkRuleAction, DvsLogNetworkRuleAction, DvsMacRewriteNetworkRuleAction, DvsPuntNetworkRuleAction, DvsRateLimitNetworkRuleAction
- Ruleset object returned from `Get-VNVDTrafficRuleSet` should have property of "parent vDPG", to be used for vDPG reconfig task (need to add vDPG property to return from `Get-VNVDTrafficFilterPolicyConfig`, `Get-VNVDTrafficRuleSet`, and `Get-VNVDTrafficRule`)
- `New-VNVDTrafficRule`
    - adds rule to TrafficRuleset
- `Remove-VNVDTrafficRule -Rule[]`
    - define cmdlet `ConfirmImpact` to `High`
    - removes a given rule from the associated ruleset on the given vDPortgroup
    - implemented, but initially with a bug (now worked around):  cannot rely on TrafficRule object's `Key` property, as that changes with every vDPortgroup reconfig, apparently (so, if iterating through several Rules, after the removal of the 1st one, the keys for the rest in the pipeline are invalid)
        - so, must do the `Process` differently so that all TrafficRule items per vDPortgroup are removed in one reconfig (or, other, less reliable ways, for which I did not opt)
    - Operating with the understanding/observation that there is only ever one (1) `Config.DefaultPortConfig.FilterPolicy.FilterConfig` per vDPortgroup (and, so, one subsequent TrafficRuleset, since a FilterConfig has one TrafficRuleset), even though the `.FilterConfig` property is of type `VMware.Vim.DvsFilterConfig[]`; so, using single TrafficRuleset per group of TrafficRules to remove; may need revisited in the future

## Get
`Get-VDPortgroup | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule`

## New traffic rule, (adding traffic rule to traffic ruleset)
`Get-VDPortgroup someVdpg | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Rule (New-VNVDTrafficRule -Direction blahh -Qualifier (New-VNVDTrafficRuleQualifier -ParmsHere))`

## eventually? Set (overwrite) all rules in the ruleset (if any) with new rule(s) specified
`Get-VDPortgroup someVdpg | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled -Rule (New-VNVDTrafficRule -Direction blahh -Qualifier (New-VNVDTrafficRuleQualifier -ParmsHere))`

## Remove some traffic rules
`Get-VDPortgroup someVdpg | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule -Name testRule0, otherRule* | Remove-VNVDTrafficRule`


## Other
- example core code, from https://communities.vmware.com/thread/493610?q=distributed%20switch%20traffic%20filter
``` PowerShell
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
```

Other info:
get VDTrafficFilterPolicyConfig:
`$viewVDPG.Config.DefaultPortConfig.FilterPolicy.FilterConfig`
