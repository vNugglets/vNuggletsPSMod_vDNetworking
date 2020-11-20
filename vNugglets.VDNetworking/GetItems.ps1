function Get-VNVDTrafficFilterPolicyConfig {
<#	.Description
	Get the VDTrafficFilterPolicy configuration for the given VDPortgroup(s) from VDSwitch(es)

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig
	Get the TrafficFilter policy config for the given VDPortgroup

	.Outputs
	VNVDTrafficFilterPolicyConfig with properties with at least VMware.Vim.DvsTrafficFilterConfig and VMware.Vim.DistributedVirtualPortgroup for the TrafficFilter policy config
#>
	[CmdletBinding()]
	[OutputType([VNVDTrafficFilterPolicyConfig])]
	param (
		## The virtual distributed portgroup for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName = 'ByVDPortgroup')][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup,

		## The View object for the virtual distributed portgroup for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "ByVDPortGroupView")][VMware.Vim.DistributedVirtualPortgroup[]]$VDPortgroupView,

		## The virtual distributed port for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByVDPort')][VMware.VimAutomation.Vds.Types.V1.VDPort[]]$VDPort,

		## The View object for the virtual distributed port for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByVDPortView")][VMware.Vim.DistributedVirtualPort[]]$VDPortView,

		## The VM nic for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByNetworkAdapter')][VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.NetworkAdapter[]]$NetworkAdapter,

		## The VM for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByVM')][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM
	) ## end param

	process {
		Switch ($PSCmdlet.ParameterSetName) {
			{"ByVDPortGroup", "ByVDPortGroupView" -contains $_} {
				## get the View objects over which to iterate (either the .ExtensionData)
				$(if ($PSCmdlet.ParameterSetName -eq "ByVDPortGroup") {$VDPortgroup | Foreach-Object {$_.ExtensionData}} else {$VDPortgroupView}) | Foreach-Object {
					## update the ViewData for this vDPG, just to be sure that all is current
					$oThisVDPGView = $_; $oThisVDPGView.UpdateViewData("Config")
					New-Object -Type VNVDTrafficFilterPolicyConfig -Property @{
						TrafficFilterPolicyConfig = $oThisVDPGView.Config.DefaultPortConfig.FilterPolicy.FilterConfig
						VDPortgroupView = $oThisVDPGView
					} ## end new-object
				} ## end foreach-object
			} ## end case

			{"ByVDPort", "ByVDPortView" -contains $_} {
				## get the View objects over which to iterate (either the .ExtensionData)
				$(if ($PSCmdlet.ParameterSetName -eq "ByVDPort") {$VDPort | Foreach-Object {$_.ExtensionData}} else {$VDPortView}) | Foreach-Object {
					## update the ViewData for this vDP, just to be sure that all is current
					## UpdateViewData not exist on port, so we have to take the long way
					$oThisVDPView = (Get-VDPort -VDPortgroup (Get-VDPortgroup -Id "DistributedVirtualPortgroup-$($_.PortgroupKey)") -Key $_.Key).ExtensionData
					$oThisVDPView.Config.Setting.FilterPolicy.FilterConfig | ForEach-Object {
						New-Object -Type VNVDTrafficFilterPolicyConfig -Property @{
							TrafficFilterPolicyConfig = $_
							VDPortView = $oThisVDPView
						} ## end new-object
					} ## end foreach-object
				} ## end foreach-object
			} ## end case

			{"ByNetworkAdapter", "ByVM" -contains $_} {
				## get the NetworkAdapter objects over which to iterate (either the the nics of the VM)
				$(if ($PSCmdlet.ParameterSetName -eq "ByVM") {$VM | Foreach-Object {$_ | Get-NetworkAdapter}} else {$NetworkAdapter}) | Foreach-Object {
					## get the vDPort View of the VM nic
					$oThisVDPView = (Get-VDPort -VDPortgroup (Get-VDPortgroup -Id "DistributedVirtualPortgroup-$($_.ExtensionData.Backing.Port.PortgroupKey)") -Key $_.ExtensionData.Backing.Port.PortKey).ExtensionData
					$oThisVDPView.Config.Setting.FilterPolicy.FilterConfig | ForEach-Object {
						New-Object -Type VNVDTrafficFilterPolicyConfig -Property @{
							TrafficFilterPolicyConfig = $_
							VDPortView = $oThisVDPView
						} ## end new-object
					} ## end foreach-object
				} ## end foreach-object
			} ## end case
		} ## end switch
	} ## end process
} ## end fn



function Get-VNVDTrafficRuleSet {
<#	.Description
	Get the DvsTrafficRuleset for the given VDTrafficFilterPolicy configuration from VDPortgroup(s), or from VDPortgroup(s) directly

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet
	Get the traffic ruleset from the TrafficFilterPolicyConfig object of a given vDPG. Can also get the ruleset from just the vDPG, but this "from TrafficFilterPolicyConfig" method is to help show the relationship between the vDPG, the TrafficFilterPolicyConfig, and the TrafficRuleset

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet
	Get the traffic ruleset directly from the given vDPG

	.Outputs
	VNVDTrafficRuleSet with properties with at least VMware.Vim.DvsTrafficRuleset and VMware.Vim.DistributedVirtualPortgroup for the Traffic rule set
#>
	[CmdletBinding(DefaultParameterSetName="ByTrafficFilterPolicyConfig")]
	[OutputType([VNVDTrafficRuleSet])]
	param (
		## The traffic filter policy config of the virtual distributed portgroup for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficFilterPolicyConfig")][VNVDTrafficFilterPolicyConfig[]]$TrafficFilterPolicyConfig,

		## The virtual distributed portgroup for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByVDPortGroup")][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup,

		## The View object for the virtual distributed portgroup for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByVDPortGroupView")][VMware.Vim.DistributedVirtualPortgroup[]]$VDPortgroupView,

		## The virtual distributed port for which to get the traffic ruleset
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByVDPort")][VMware.VimAutomation.Vds.Types.V1.VDPort[]]$VDPort,

		## The View object for the virtual distributed port for which to get the traffic ruleset
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "ByVDPortView")][VMware.Vim.DistributedVirtualPort[]]$VDPortView,

		## The VM nic for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByNetworkAdapter')][VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.NetworkAdapter[]]$NetworkAdapter,

		## The VM for which to get the traffic filtering and marking policy configuration
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByVM')][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM
	) ## end param

	process {
		# get the traffic filtering and marking policy configuration from portgroup or port
		Switch ($PSCmdlet.ParameterSetName) {
			"ByVDPortGroup" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -VDPortgroup $VDPortgroup }
			"ByVDPortGroupView" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -VDPortgroupView $VDPortgroupView }
			"ByVDPort" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -VDPort $VDPort }
			"ByVDPortView" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -VDPortView $VDPortView }
			"ByNetworkAdapter" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -NetworkAdapter $NetworkAdapter }
			"ByVM" { $TrafficFilterPolicyConfig = Get-VNVDTrafficFilterPolicyConfig -VM $VM }
		} ## end switch

		$TrafficFilterPolicyConfig | Foreach-Object {
			$oThisTrafficPolicyConfig = $_
			$_.TrafficFilterPolicyConfig | Foreach-Object {
				New-Object -Type VNVDTrafficRuleSet -Property @{
					TrafficRuleset        = $_.TrafficRuleset
					TrafficRulesetEnabled = $_.TrafficRuleset.Enabled
					NumTrafficRule        = ($_.TrafficRuleset.Rules | Measure-Object).Count
					VDPortgroupView       = $oThisTrafficPolicyConfig.VDPortgroupView
					VDPortView            = $oThisTrafficPolicyConfig.VDPortView
				} ## end new-object
			} ## end foreach-object
		} ## end foreach-object
	} ## end process
} ## end function



function Get-VNVDTrafficRule {
<#	.Description
	Get the VDTrafficRule for the TrafficRuleset from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
	Get the traffic rules from the TrafficeRuleset, which was gotten from the vDPG's TrafficFilterPolicyConfig

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule myTestRule*
	Get traffic rules whose name is like "myTestRule*"

	.Outputs
	VNVDTrafficRule with at least properties for VMware.Vim.DvsTrafficRule and VMware.Vim.DistributedVirtualPortgroup for the Traffic rule set rule
#>
	[CmdletBinding(DefaultParameterSetName="Default")]
	[OutputType([VNVDTrafficRule])]
	param (
		## The name(s) of the Traffic Rule(s) to return (accepts wildcards). If -Name or -LiteralName not specified, will return all Traffic Rules for the given traffic rule set
		[parameter(ParameterSetName="ByName", Position=0)][String[]]$Name,

		## The name(s) of the Traffic Rule(s) to return (exact match only, no wildcarding employed). If -Name or -LiteralName not specified, will return all Traffic Rules for the given traffic rule set
		[parameter(ParameterSetName="ByLiteralName")][String[]]$LiteralName,

		## The traffic ruleset from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule(s)
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VNVDTrafficRuleSet[]]$TrafficRuleset
	) ## end param

	process {
		$TrafficRuleset | Foreach-Object {
			$oThisTrafficRuleset = $_
			$arrRulesOfInterest =
			## if -Name was passed, only return rules whose descriptions are like the given name value(s)
			if ($PSBoundParameters.ContainsKey("Name")) {$_.TrafficRuleset.Rules | Where-Object {$oThisDescription = $_.Description; ($Name | Foreach-Object {$oThisDescription -like $_}) -contains $true}}
			elseif ($PSBoundParameters.ContainsKey("LiteralName")) {$_.TrafficRuleset.Rules | Where-Object {$LiteralName -contains $_.Description}}
			else {$_.TrafficRuleset.Rules | Where-Object {$null -ne $_}}
			$arrRulesOfInterest | Foreach-Object {
				$oThisTrafficRule = $_
				New-Object -Type VNVDTrafficRule -Property @{
					Name = $oThisTrafficRule.Description
					TrafficRule = $oThisTrafficRule
					VDPortgroupView = $oThisTrafficRuleset.VDPortgroupView
					VDPortView = $oThisTrafficRuleset.VDPortView
					VNVDTrafficRuleSet = $oThisTrafficRuleset
				} ## end new-object
			} ## end foreach-object
		} ## end foreach-object
	} ## end process
} ## end function



function Get-VNVDTrafficRuleQualifier {
<#	.Description
	Get the VDTrafficRule Qualifier for the TrafficRule from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule | Get-VNVDTrafficRuleQualifier
	Get the traffic rules qualifiers from the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig

	.Outputs
	VMware.Vim.DvsNetworkRuleQualifier
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsNetworkRuleQualifier])]
	param (
		## The traffic ruleset rule from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule qualifier(s)
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficRule")][VNVDTrafficRule[]]$TrafficRule
	) ## end param

	process {
		$TrafficRule | Foreach-Object {
			$_.TrafficRule.Qualifier | Where-Object {$null -ne $_} | Foreach-Object {
				## get the qualifier TypeName short name (like, if TypeName is "VMware.Vim.DvsIpNetworkRuleQualifier", this will be "DvsIpNetworkRuleQualifier")
				$strQualifierTypeShortname = ($_ | Get-Member | Select-Object -First 1).TypeName.Split(".") | Select-Object -Last 1
				## the properties to select for this Qualifier object
				$arrPropertyForSelectObject = @{n="QualifierType"; e={$strQualifierTypeShortname}}, "*"
				## if the Qualifier object is of type VMware.Vim.DvsSystemTrafficNetworkRuleQualifier, essentially "expand" the TypeOfSystemTraffic.Value property to be one level up in the return object
				if ($strQualifierTypeShortname -eq "DvsSystemTrafficNetworkRuleQualifier") {$arrPropertyForSelectObject += @{n="TypeOfSystemTraffic_Name"; e={$_.TypeOfSystemTraffic.Value}}}
				$_ | Select-Object -Property $arrPropertyForSelectObject
			} ## end foreach-object
		} ## end foreach-object
	} ## end process
} ## end function



function Get-VNVDTrafficRuleAction {
<#	.Description
	Get the VDTrafficRule Action for the TrafficRule from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule | Get-VNVDTrafficRuleAction
	Get the traffic rules action from the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig

	.Outputs
	VMware.Vim.DvsNetworkRuleAction
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsNetworkRuleAction])]
	param (
		## The traffic ruleset rule from the traffic filter policy of the virtual distributed portgroup for which to get the traffic rule action
		[parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByTrafficRule")][VNVDTrafficRule[]]$TrafficRule
	) ## end param

	process {
		$TrafficRule | Foreach-Object {
			$_.TrafficRule.Action
		} ## end foreach-object
	} ## end process
} ## end function



function Get-VNVSwitchByVMHostNetworkAdapter {
<#	.Description
	Get the virtual switch (standard or distributed) with which the given VMHostNetworkAdapter physical NIC is associated, if any.

	.Example
	Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic2 | Get-VNVSwitchByVMHostNetworkAdapter
	Get the vSwitch with which VMNIC2 on myVMHost0.dom.com is associated

	.Outputs
	Virtual standard- or distributed switch with which given physical VMHost network adapter is associated, if any
#>
	[CmdletBinding()]
	param(
		## The VMHostNetworkAdapter (physical NIC) for which to get the vSwitch
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Types.Host.NIC.PhysicalNic[]]$VMHostNetworkAdapter
	) ## end param

	process {
		$VMHostNetworkAdapter | Foreach-Object {
			$oThisVMHostNetworkAdapter = $_
			if ($oAssociatedVSwitch = $oThisVMHostNetworkAdapter.VMHost.ExtensionData.Config.Network.Vswitch, $oThisVMHostNetworkAdapter.VMHost.ExtensionData.Config.Network.ProxySwitch | Foreach-Object {$_} | Where-Object {$_.Pnic -contains $oThisVMHostNetworkAdapter.Id}) {
				switch ($oAssociatedVSwitch) {
					## vSS
					{$_ -is [VMware.Vim.HostVirtualSwitch]} {
						$oThisVMHostNetworkAdapter.VMHost | Get-VirtualSwitch -Standard -Name $oAssociatedVSwitch.Name
						break
					} ## end case
					## vDSwitch
					{$_ -is [VMware.Vim.HostProxySwitch]} {
						$oThisVMHostNetworkAdapter.VMHost | Get-VDSwitch -Name $oAssociatedVSwitch.DvsName
						break
					} ## end case
					default {Write-Warning "vSwitch not of expected type of either [VMware.Vim.HostVirtualSwitch] or [VMware.Vim.HostProxySwitch]. What kind of vSwitch is it? $_"}
				} ## end switch
			} ## end if
			else {Write-Verbose "No vSwitch associated with VMNIC '$($oThisVMHostNetworkAdapter.Name)' found on VMHost '$($oThisVMHostNetworkAdapter.VMHost.Name)'"}
		} ## end Foreach-Object
	} ## end process
} ## end fn