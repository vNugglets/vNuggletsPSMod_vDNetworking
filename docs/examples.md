### Examples for vNugglets.VDNetworking PowerShell module for VMware vSphere Virtual Distributed Networking management

#### `Get-VNVDTrafficFilterPolicyConfig`: Get the VDTrafficFilterPolicy configuration for the given VDPortgroup(s) from VDSwitch(es)

```PowerShell
## Get the TrafficFilter policy config for the given VDPortgroup
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig
```

#### `Get-VNVDTrafficRule`: Get the VDTrafficRule for the TrafficRuleset from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

```PowerShell
## Get the traffic rules from the TrafficeRuleset, which was gotten from the vDPG's TrafficFilterPolicyConfig
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule

## Get traffic rules whose name is like "myTestRule*"
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule myTestRule*
```

#### `Get-VNVDTrafficRuleAction`: Get the VDTrafficRule Action for the TrafficRule from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

```PowerShell
## Get the traffic rules action from the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule | Get-VNVDTrafficRuleAction
```

#### `Get-VNVDTrafficRuleQualifier`: Get the VDTrafficRule Qualifier for the TrafficRule from the given VDTrafficFilterPolicy configuration from VDPortgroup(s)

```PowerShell
## Get the traffic rules qualifiers from the traffic rules from the TrafficeRuleset property of the TrafficFilterPolicyConfig
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRule | Get-VNVDTrafficRuleQualifier
```

#### `Get-VNVDTrafficRuleSet`: Get the DvsTrafficRuleset for the given VDTrafficFilterPolicy configuration from VDPortgroup(s), or from VDPortgroup(s) directly

```PowerShell
## Get the traffic ruleset from the TrafficFilterPolicyConfig object of a given vDPG. Can also get the ruleset from just the vDPG, but this "from TrafficFilterPolicyConfig" method is to help show the relationship between the vDPG, the TrafficFilterPolicyConfig, and the TrafficRuleset
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet

## Get the traffic ruleset directly from the given vDPG
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet
```

#### `Get-VNVSwitchByVMHostNetworkAdapter`: Get the virtual switch (standard or distributed) with which the given VMHostNetworkAdapter physical NIC is associated, if any.

```PowerShell
## Get the vSwitch with which VMNIC2 on myVMHost0.dom.com is associated
Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic2 | Get-VNVSwitchByVMHostNetworkAdapter
```

#### `New-VNVDTrafficRule`: Make new Traffic Rule and add it to the given Traffic Ruleset of a vDPortgroup traffic filter policy

```PowerShell
## Create a new Traffic Rule that has two Qualifiers and add it to the given TrafficRuleset from the given vDPortgroup. The new Traffic Rule allows vMotion traffic from given source network
Get-VDPortGroup myVDPG0 | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "Allow vMotion from source network" -Action (New-VNVDTrafficRuleAction -Allow) -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vMotion), (New-VNVDTrafficRuleQualifier -SourceIpAddress 10.0.0.0/8)

## Create a new Traffic Rule that has two Qualifiers and add it to the given TrafficRuleset from the given vDPortgroup. The new Traffic Rule adds a DSCP tag with value 8 to VM traffic from given source IP
Get-VDPortGroup myVDPG0 | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "Apply DSCP tag to VM traffic from given address" -Action (New-VNVDTrafficRuleAction -DscpTag 8) -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType virtualMachine), (New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.1.2) -Direction outgoingPackets
```

#### `New-VNVDTrafficRuleAction`: Make new VMware.Vim.DvsNetworkRuleAction, for use in creating vDPortgroup traffic filter policy rule.  Currently supports creating Rule Actions of types DvsAcceptNetworkRuleAction ("Allow"), DvsDropNetworkRuleAction, and DvsUpdateTagNetworkRuleAction

```PowerShell
## Create a new DvsAcceptNetworkRuleAction object that will specify an action of "Allow packet"
New-VNVDTrafficRuleAction -Allow

## Create a new DvsDropNetworkRuleAction object that will specify an action of "Drop packet"
New-VNVDTrafficRuleAction -Drop

## Create a new DvsUpdateTagNetworkRuleAction object that will specify an action of "tag with DSCP value of 8, and clear the QoS tag of packet"
New-VNVDTrafficRuleAction -DscpTag 8 -QosTag 0
```

#### `New-VNVDTrafficRuleQualifier`: Make new VMware.Vim.DvsNetworkRuleQualifier, for use in creating vDPortgroup traffic filter policy rule

```PowerShell
## Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is vMotion
New-VNVDTrafficRuleQualifier -SystemTrafficType vMotion

## Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is _not_ Management traffic
New-VNVDTrafficRuleQualifier -SystemTrafficType Management -Negate

## Create a new DvsIpNetworkRuleQualifier for traffice from the given source IP that is _not_ to the given destination network, using TCP (6) protocol, and that is from source ports of 443 or 444
New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.1.2 -DestinationIpAddress 10.0.0.0/8 -NegateDestinationIpAddress -Protocol 6 -SourceIpPort 443-444

## Create a new DvsMacNetworkRuleQualifier for traffic from the source MAC address, that is _not_ to the destination MAC, that is using EtherType 0x8922, and that is not on VLAN 10
New-VNVDTrafficRuleQualifier -SourceMacAddress 00:00:56:01:23:45 -DestinationMacAddress 00:00:56:78:90:12 -NegateDestinationMacAddress -EtherTypeProtocol 0x8922 -VlanId 10 -NegateVlanId

## Create a new DvsMacNetworkRuleQualifier for traffic from the any source MAC address in the given MAC range and that is on VLAN 22
New-VNVDTrafficRuleQualifier -SourceMacAddress 00:A0:C9:14:C8:29/FF:FF:00:FF:00:FF -VlanId 22
```

#### `Remove-VNVDTrafficRule`: Remove a Traffic Rule from the given Traffic Ruleset of a vDPortgroup traffic filter policy

```PowerShell
## Get the TrafficRules named like "test*" from the TrafficRuleSet for the given vDPortGroup and delete them
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule -Name test* | Remove-VNVDTrafficRule
```

#### `Set-VNVDTrafficRuleSet`: Set attributes on the DvsTrafficRuleset (like Enable/Disable it) for the given TrafficRuleSet

```PowerShell
## Get the traffic ruleset from the TrafficFilterPolicyConfig object of a given vDPG and Enable it
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficFilterPolicyConfig | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled

## Get the traffic ruleset from the given vDPG and Disable it
Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled:$false
```

#### `Set-VNVMHostNetworkAdapterVDUplink`: Set the VDSwitch Uplink for a VMHost physical NIC ("VMNIC") on the VDSwitch of which the VMNIC is already a part

```PowerShell
## Set the VMNIC "vminic3" from VMHost myVMHost0.dom.com to be in VDUplink "Uplinks-02" on VDS myVDSwitch0 (the vDSwitch of which VMNIC3 is a part)
Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic3 | Set-VNVMHostNetworkAdapterVDUplink -UplinkName Uplinks-02

## Set the VMNICs "vminic2", "vminic3" from VMHost myVMHost0.dom.com to be in VDUplinks "Uplinks-01", "Uplinks-02" on VDS myVDSwitch0 (the vDSwitch of which VMNIC2 and VMNIC3 are a part)
## Could then check out the current status like:
## Get-VDSwitch myVDSwitch0 | Get-VDPort -Uplink | Where-Object {$_.ProxyHost.Name -eq "myVMHost0.dom.com"} | Select-Object key, ConnectedEntity, ProxyHost, Name | Sort-Object ProxyHost, Name
Set-VNVMHostNetworkAdapterVDUplink -VMHostNetworkAdapter (Get-VMHost myVMHost0.dom.com | Get-VMHostNetworkAdapter -Name vmnic2, vmnic3) -UplinkName Uplinks-01, Uplinks-02
```

