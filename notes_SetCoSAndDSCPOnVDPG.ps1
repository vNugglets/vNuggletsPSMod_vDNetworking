## Sample code to set Class of Service (CoS) and Differentiated Service Code Point (DSCP) values on vDPGs on a VDSwitch
## params to take for new FilterPolicy
vDPG
Name
Action
[switch]Enabled = $true
[int]CoSValue -- nullable
[int]DSCPValue -- nullable
[ValidateSet("incomingPackets","outgoingPackets","both")][VMware.Vim.DvsNetworkRuleDirectionType]TrafficDirection
[VMware.Vim.DvsNetworkRuleQualifier[]]RuleQualifier


New-NetworkRuleQualifier.ps1, Get-VDTrafficFilterPolicyConfig.ps1, Get-VDTrafficRule.ps1, Get-VDTrafficRuleQualifier.ps1

## something like
# get-vdpg | get-vdtrafficfilter | new-vdtrafficrule
# get-vdpg | get-vdtrafficfilter | get-vdtrafficrule


<# couple of examples
## from https://communities.vmware.com/thread/493610?q=distributed%20switch%20traffic%20filter
$dvSwName = 'dvSw1'
$dvPgNames = 'dvPg1'

$dvSw = Get-VDSwitch -Name $dvSwName

# Enable LBT
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



# or, partially working, from https://www.reddit.com/r/vmware/comments/6ughyq/powercli_configure_traffic_filtering_and_marking/
$dvSwName = 'name-of-dvsw'
$dvPgNames = 'name-of-pg'

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


    $bu01ip4 = New-Object VMware.Vim.DvsTrafficRule
    $bu01ip4.Description = 'Tag AF23 to IP4 BU01'
    $bu01ip4.Direction = 'both'
# of basetype VMware.Vim.DvsNetworkRuleQualifier
    $bu01ip4Props = New-Object VMware.Vim.DvsIpNetworkRuleQualifier
    $bu01ip4Props.protocol = ${6}
    $bu01ip4Props.destinationAddress = ${ip:172.16.14.31}
    $bu01ip4.qualifier += $bu01ip4Props


    $action = New-Object VMware.Vim.DvsUpdateTagNetworkRuleAction
    $action.DSCPTag = 22


    $bu01ip4.Action += $action
    $ruleSet.Rules += $bu01ip4

    $filter.TrafficRuleSet += $ruleSet
    spec.DefaultPortConfig.FilterPolicy.FilterConfig += $filter
    $pg.ReconfigureDVPortgroup($spec)
}
#>
