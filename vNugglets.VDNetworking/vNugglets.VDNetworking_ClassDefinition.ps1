## make some Class definitions for objects
## base class from which all shall inherit
class VNVDBase {}

## VDPortgroup Filter Policy Config item, to include the "parent" vDPG property for further context of the object
class VNVDTrafficFilterPolicyConfig : VNVDBase {
	## the TrafficFilterPolicyConfig item for this object
	[VMware.Vim.DvsTrafficFilterConfig[]]$TrafficFilterPolicyConfig

	## the full View object for the vDPG and vDP that is the "parent" of this object
	[VMware.Vim.DistributedVirtualPortgroup]$VDPortgroupView
	[VMware.Vim.DistributedVirtualPort]$VDPortView
	
	## constructor
	# VNVDTrafficFilterPolicyConfig() {}
} ## end class


## VDPortgroup Filter Policy Config ruleset item, to include the "parent" vDPG property for further context of the object
class VNVDTrafficRuleSet : VNVDBase {
	## the TrafficFilter ruleset item for this object
	[VMware.Vim.DvsTrafficRuleset]$TrafficRuleset

	## boolean: is the TrafficFilter ruleset item for this object "enabled"?
	[Boolean]$TrafficRulesetEnabled

	## number of Traffic Rules in this TrafficRuleSet. And int, or $null
	$NumTrafficRule

	## the full View object for the vDPG and vDP that is the "parent" of this object
	[VMware.Vim.DistributedVirtualPortgroup]$VDPortgroupView
	[VMware.Vim.DistributedVirtualPort]$VDPortView
} ## end class


## VDPortgroup Filter Policy Config ruleset rule, to include the "parent" vDPG property for further context of the object
class VNVDTrafficRule : VNVDBase {
	## the description (name) of the traffic rule
	[String]$Name

	## the TrafficFilter ruleset rule item for this object
	[VMware.Vim.DvsTrafficRule]$TrafficRule

	## the full View object for the vDPG and vDP that is the "parent" of this object
	[VMware.Vim.DistributedVirtualPortgroup]$VDPortgroupView
	[VMware.Vim.DistributedVirtualPort]$VDPortView

	## the "parent" VNVDTrafficRuleSet to which this TrafficRule belongs
	[VNVDTrafficRuleSet]$VNVDTrafficRuleSet
} ## end class
