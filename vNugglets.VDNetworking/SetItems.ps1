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
		[Switch]$Enabled,

		## Switch: Override the TrafficRuleSet(s) from PortGroup?  And, use "-Override:$false" to inherited TrafficRuleSet(s)
		[Switch]$Override
	) ## end param

	process {
		$TrafficRuleSet | Foreach-Object {
			$oThisVNVDTrafficRuleset = $_
			if ($null -ne $oThisVNVDTrafficRuleset.VDPortgroupView) {
				$strMsgForShouldProcess_Target = "Traffic ruleset '{0}' on vDPG '{1}'" -f $oThisVNVDTrafficRuleset.TrafficRuleset.Key, $oThisVNVDTrafficRuleset.VDPortgroupView.Name
			} ## end if
			else {
				$strMsgForShouldProcess_Target = "Traffic ruleset '{0}' on vDP '{1}'" -f $oThisVNVDTrafficRuleset.TrafficRuleset.Key, $oThisVNVDTrafficRuleset.VDPortView.Key
			} ## end else
			if ($PSBoundParameters.ContainsKey("Override")) {
				$strMsgForShouldProcess_Action = "{0} ruleset" -f $(if ($Override) {"Override"} else {"UnOverride"})
				if ($PSCmdlet.ShouldProcess($strMsgForShouldProcess_Target, $strMsgForShouldProcess_Action)) {
					try {
						## use the helper function to add this new TrafficRule to the TrafficRuleSet Rules array
						Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oThisVNVDTrafficRuleset -Override:$Override
					} ## end try
					catch {Throw $_}
				} ## end if
			} ## end if
			if ($PSBoundParameters.ContainsKey("Enabled")) {
				$strMsgForShouldProcess_Action = "{0} ruleset" -f $(if ($Enabled) {"Enable"} else {"Disable"})
				if ($PSCmdlet.ShouldProcess($strMsgForShouldProcess_Target, $strMsgForShouldProcess_Action)) {
					try {
						## use the helper function to add this new TrafficRule to the TrafficRuleSet Rules array
						Set-VNVDTrafficRuleset_helper -TrafficRuleSet $oThisVNVDTrafficRuleset -Enabled:$Enabled
					} ## end try
					catch {Throw $_}
				} ## end if
			} ## end if
		} ## end foreach-object
	} ## end process
} ## end function


function Set-VNVMHostNetworkAdapterVDUplink {
<#	.Description
	Set the VDSwitch Uplink for a VMHost physical NIC ("VMNIC") on the VDSwitch of which the VMNIC is already a part

	.Example
	Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic3 | Set-VNVMHostNetworkAdapterVDUplink -UplinkName Uplinks-02
	Set the VMNIC "vminic3" from VMHost myVMHost0.dom.com to be in VDUplink "Uplinks-02" on VDS myVDSwitch0 (the vDSwitch of which VMNIC3 is a part)

	.Example
	Set-VNVMHostNetworkAdapterVDUplink -VMHostNetworkAdapter (Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic2, vmnic3) -UplinkName Uplinks-01, Uplinks-02
	Set the VMNICs "vminic2", "vminic3" from VMHost myVMHost0.dom.com to be in VDUplinks "Uplinks-01", "Uplinks-02" on VDS myVDSwitch0 (the vDSwitch of which VMNIC2 and VMNIC3 are a part)
	Could then check out the current status like:
	Get-VDSwitch myVDSwitch0 | Get-VDPort -Uplink | Where-Object {$_.ProxyHost.Name -eq "myVMHost0.dom.com"} | Select-Object key, ConnectedEntity, ProxyHost, Name | Sort-Object ProxyHost, Name

	.Notes
	One cannot put two VMNICs from a VMHost in the same vDUplink -- they should go into separate/unique vDUplinks
	Requires that VMHostNetworkAdapter(s) are all associated with a single vDSwitch (not VMNICs from multiple vDSwitches) and that the vSwitch type is _Distributed_ (not Standard)

	Function checks that:
	- all VMHostNetworkAdapters specified are on same VMHost and same vDSwitch
	- all UplinkNames specified are on same vDSwitch

	The core NetworkSystem and config spec syntax is based on LucD's post (of course) at https://code.vmware.com/forums/2530/vsphere-powercli#576477?start=15&tstart=0

	.Outputs
	VMware.VimAutomation.Vds.Types.V1.VDPort for the Uplink VDPort with which the VMNIC(s) are now affiliated
#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
	[OutputType([VMware.VimAutomation.Vds.Types.V1.VDPort])]
	param(
		## The VMHost Network Adapter(s) ("VMNIC") to set in a given vDUplink. If more than one specified, then specify the same number of -UplinkName values, too. The first VMHostNetworkAdapter will be set to the first UplinkName, the second to the second UplinkName, and so on
		[parameter(Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Types.Host.NIC.PhysicalNic[]]$VMHostNetworkAdapter,

		## The name(s) of the vDUplink with which to associate the VMNIC. If more than one specified, then specify the same number of -VMHostNetworkAdapter values, too
		[parameter(Mandatory=$true)][String[]]$UplinkName
	) ## end param

	process {
		## make sure that the same number of VMNICs and UplinkNames were provided
		if (($VMHostNetworkAdapter | Measure-Object).Count -eq ($UplinkName | Measure-Object).Count) {
			## the VMHost(s) of these VMNICs
			$oTargetVMHost = $VMHostNetworkAdapter.VMHost | Select-Object -Unique
			## if the VMNICs are from more than one VMHost
			if (($oTargetVMHost | Measure-Object).Count -gt 1) {Write-Error "VMHostNetworkAdapters provided are from more than one VMHost. Specify VMNICs from just a single VMHost"}
			## else, the VMNICs are from the same VMHost
			else {
				## get VDSwitch(es) of which VMNIC is a part (uses another function in this module)
				$arrTargetVSwitches = $VMHostNetworkAdapter | Get-VNVSwitchByVMHostNetworkAdapter
				## get the unique vSwitches associated with these VMNICs (should be only one vSwitch)
				$oTargetVDSwitch = $arrTargetVSwitches | Select-Object -Unique

				## if all VMHostNetworkAdapters are associated with vSwitches (num VMNICs is different than num of retrieved vSwitches), and all VMNICs are from same vSwitch
				if ((($arrTargetVSwitches | Measure-Object).Count -eq $VMHostNetworkAdapter.Count) -and (($oTargetVDSwitch | Measure-Object).Count -eq 1)) {
					## get the DistributedVirtualSwitchHostMember object for this VMHost and vDSwitch; this object has things like the VDPorts that are the Uplink ports for this VMHost on this vDSwitch, the current PNIC backing info for this VMHost/vDSwitch (if any), etc.
					$oVDSwitchHostMember = $oTargetVDSwitch.ExtensionData.Config.Host | Where-Object {$_.Config.Host.ToString() -eq $oTargetVMHost.Id}
					## get the vDUplink ports for this VDSwitch and this VMHost -- the <vDSwitch>.ExtensionData.Config.Host objects have subsequent property ".Config.Host" (yes, same property names again) from which to determine the corresponding item by VMHost ID
					$arrVDUplinks_thisVDS_thisVMHost = Get-VDPort -Key $oVDSwitchHostMember.UplinkPortKey -VDSwitch $oTargetVDSwitch

					## get the UplinkName(s) specified that are not defined on the target vDSwitch (as returned by Compare-Object with a property of SideIndicator with a value of "=>" -- meaning, they were in the DifferenceObject and not the ReferenceObject)
					$arrUplinkNamesNameOnVDSwitch = Compare-Object -ReferenceObject $arrVDUplinks_thisVDS_thisVMHost.Name -DifferenceObject $UplinkName | Where-Object {$_.SideIndicator -eq "=>"}
					## if all values of $UplinkName are valid for this VDSwitch
					if ($null -eq $arrUplinkNamesNameOnVDSwitch) {
						## the TODO of "check that there are any arrVDUplinks_thisVDS_thisVMHost where the VMNIC <--> UplinkName correlation needs changed" would start about here:

						## make the messages for ShouldProcess()
						$strShouldProcessMsg_target = "vDSwitch '{0}' for VMHost '{1}'" -f $oTargetVDSwitch.Name, $oTargetVMHost.Name
						$strShouldProcessMsg_action = "Set VMNIC{0} '{1}' to be in vDUplink{0} '{2}'" -f $(if ($VMHostNetworkAdapter.Count -ne 1) {"s"}), ($VMHostNetworkAdapter.Name -join ", "), ($UplinkName -join ", ")
					 	if ($PSCmdlet.ShouldProcess($strShouldProcessMsg_target, $strShouldProcessMsg_action)) {
							## get NetworkSystem for the VMHost for this VMNIC
							$viewNetworkSystem_thisVMHost = Get-View -Id $oTargetVMHost.ExtensionData.ConfigManager.NetworkSystem -Property NetworkConfig, NetworkInfo

							## the existing PnicSpec objects for this VDSwitchHostMemeber.Config object
							$arrExistingPnicSpec = $oVDSwitchHostMember.Config.Backing.PnicSpec | Where-Object {$VMHostNetworkAdapter.Name -notcontains $_.PnicDevice}
							$arrNewPnicSpec = $VMHostNetworkAdapter | Foreach-Object -begin {$intI = 0} -process {
								## the UplinkName that corresponds positionally in the $UplinkName param to the position in the $VMHostNetworkAdapter param that we currently are
								$strUplinkNameToUseForThisVMNic = $UplinkName | Select-Object -First 1 -Skip $intI
								New-Object -Type VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec -Property @{
									PnicDevice = $_.Name
									UplinkPortKey = ($arrVDUplinks_thisVDS_thisVMHost | Where-Object {$_.Name -eq $strUplinkNameToUseForThisVMNic}).Key
								} ## end New-Object
								$intI++
							} ## end Foreach-Object

							## make reconfigSpec to use to UpdateNetworkConfig() on NetworkSystem
							$oHostNetworkConfig_toUse = New-Object -Type VMware.Vim.HostNetworkConfig -Property @{
								ProxySwitch = @(
									New-Object -Type VMware.Vim.HostProxySwitchConfig -Property @{
										Uuid = $oTargetVDSwitch.ExtensionData.Uuid
										ChangeOperation = [VMware.Vim.HostConfigChangeOperation]::edit
										Spec = New-Object -Type VMware.Vim.HostProxySwitchSpec -Property @{
											Backing = New-Object -Type VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking -Property @{
												## the PnicSpecs from above -- the existing "other" ones for other VMNICs on this vDS for this VMHost, and the new PnicSpec(s) for the VMHostNetworkAdapter(s)
												PnicSpec = $arrExistingPnicSpec, $arrNewPnicSpec | Where-Object {$null -ne $_} | Foreach-Object {$_}
											} ## end New-Object
										} ## end New-Object
									} ## end New-Object
								) ## end array
							} ## end New-Object
							try {
								## do the UpdateNetworkConfig()
								$oHostNetworkConfigResult = $viewNetworkSystem_thisVMHost.UpdateNetworkConfig($oHostNetworkConfig_toUse, [VMware.Vim.HostConfigChangeMode]::modify)
								## return an object with the VMNIC and vDUplink info for vDUplinks for this VMHost on this vDSwitch
								Get-VDPort -Key $oVDSwitchHostMember.UplinkPortKey -VDSwitch $oTargetVDSwitch | Sort-Object ProxyHost, Name
							} ## end try
							catch {$PSCmdlet.ThrowTerminatingError($_)}
						} ## end if ShouldProcess()

						## the TODO of "check that there are any arrVDUplinks_thisVDS_thisVMHost where the VMNIC <--> UplinkName correlation needs changed" would end about here
					} ## end if all values of $UplinkName are valid for this VDSwitch

					else {
						$intNumSpecifiedUplinkNamesNotOnThisVSwitch = ($arrUplinkNamesNameOnVDSwitch | Measure-Object).Count
						Write-Error ("Uplink{0} '{1}' {2} not in '{3}' for vDSwitch '{4}', in which '{5}' take part. Please specify only Uplink names that are in use on this vSwitch." -f $(if ($intNumSpecifiedUplinkNamesNotOnThisVSwitch -ne 1) {"s"}), ($arrUplinkNamesNameOnVDSwitch.InputObject -join ", "), $(if ($intNumSpecifiedUplinkNamesNotOnThisVSwitch -ne 1) {"are"} else {"is"}), ($arrVDUplinks_thisVDS_thisVMHost.Name -join ", "), $oTargetVDSwitch.Name, ($VMHostNetworkAdapter.Name -join ", "))
					} ## end else
				} ## end if all VMHostNetworkAdapters are associated with vSwitches (num VMNICs is different than num of retrieved vSwitches), and all VMNICs are from same vSwitch

				else {Write-Error "Either the VMNICs specified are not all associated with a vSwitch, or are not all are associated with the same vSwitch. Please check that all VMNICs are a part of the same vDSwitch"}
			} ## end else the VMNICs are from the same VMHost
		} ## end if same number of VMNICs and UplinkNames were provided
		else {Write-Error ("A different number of VMNICs ({0}) and UplinkNames ({1}) were specified. Please specify the same number of values for -VMHostNetworkAdapter and -UplinkName" -f $VMHostNetworkAdapter.Count, $UplinkName.Count)}
	} ## end process
} ## end fn