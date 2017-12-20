function New-VNVDNetworkRuleQualifier {
<#	.Description
	Make new VMware.Vim.DvsNetworkRuleQualifier, for use in creating vDPortgroup traffic filter policy rule

	.Example
	New-VNVDNetworkRuleQualifier -SystemTrafficType vMotion
	Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is vMotion

	.Example
	New-VNVDNetworkRuleQualifier -SystemTrafficType Management -Negate
	Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is _not_ Management traffic

	.Example
	New-VNVDNetworkRuleQualifier -SourceIpAddress 172.16.1.2 -DestinationIpAddress 10.0.0.0/8 -NegateDestinationIpAddress -Protocol 6 -SourceIpPort 443-444
	Create a new DvsIpNetworkRuleQualifier for traffice from the given source IP that is _not_ to the given destination network, using TCP (6) protocol, and that is from source ports of 443 or 444

	.Example
	New-VNVDNetworkRuleQualifier -SourceMacAddress 00:00:56:01:23:45 -DestinationMacAddress 00:00:56:78:90:12 -NegateDestinationMacAddress -EtherTypeProtocol 0x8922 -VlanId 10 -NegateVlanId
	Create a new DvsMacNetworkRuleQualifier for traffic from the source MAC address, that is _not_ to the destination MAC, that is using EtherType 0x8922, and that is not on VLAN 10

	.Example
	New-VNVDNetworkRuleQualifier -SourceMacAddress 00:A0:C9:14:C8:29/FF:FF:00:FF:00:FF -VlanId 22
	Create a new DvsMacNetworkRuleQualifier for traffic from the any source MAC address in the given MAC range and that is on VLAN 22

	.Outputs
	VMware.Vim.DvsNetworkRuleQualifier
#>
	[OutputType([VMware.Vim.DvsNetworkRuleQualifier])]
	param (
		## Type of system traffic, for use in making SystemTraffic network rule qualifier
		[parameter(Mandatory=$true, ParameterSetName="SystemTrafficNetworkRuleQualifier")][VMware.Vim.DistributedVirtualSwitchHostInfrastructureTrafficClass]$SystemTrafficType,

		## Switch:  negate the type of system traffic?  If $true, then this has the effect of "not SystemTrafficType", like "not vMotion traffic"
		[parameter(ParameterSetName="SystemTrafficNetworkRuleQualifier")][Switch]$NegateSystemTrafficType,


		## IP qualifier of the traffic source, either a single IP, or a CIDR-notation network. If this parameter is omitted (or $null), it will match "any IPv4 or any IPv6 address". Currently accepts IPv4 address / CIDR network
		#
		# Single IP example:  172.16.1.2
		# CIDR Network example:  10.0.0.0/8
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidateScript({($_ -match "^(\d{1,3}\.){3}\d{1,3}(/\d{1,2})?$") -and ([System.Net.IPAddress]::TryParse($_.Split("/")[0], [ref]$null))})]
		[String]$SourceIpAddress,

		## Switch:  negate the source IP address?  If $true, then this has the effect of "not source IP", like "not traffic from 10.0.0.0/8"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateSourceIpAddress,

		## IP qualifier of the traffic destination, either a single IP, or a CIDR-notation network. If this parameter is omitted (or $null), it will match "any IPv4 or any IPv6 address". Currently accepts IPv4 address / CIDR network
		# See description of parameter -SourceIpAddress for more information.
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidateScript({($_ -match "^(\d{1,3}\.){3}\d{1,3}(/\d{1,2})?$") -and ([System.Net.IPAddress]::TryParse($_.Split("/")[0], [ref]$null))})]
		[String]$DestinationIpAddress,

		## Switch:  negate the destination IP address?  If $true, then this has the effect of "not destination IP", like "not traffic to 10.0.0.0/8"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateDestinationIpAddress,

		## Protocol number used. Examples: ICMP is 1, TCP is 6, UDP is 17. Per VMware documentation, "the valid value for a protocol is got from IANA assigned value for the protocol. This can be got from RFC 5237 and IANA website section related to protocol numbers".  See https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml for valid IPv4 protocol numbers
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Int]$Protocol,

		## Switch: negate protocol? If $true, then this has the effect of "not this protocol", like "not traffic to using protocol TCP (6)"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateProtocol,

		## IP Port of the traffic source, either a single IP port, or a range of IP ports. Examples:  "443" or "80-1024"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidatePattern("^\d+(-\d+)?$")][String]$SourceIpPort,

		## Switch:  negate the source IP port?  If $true, then this has the effect of "not source IP port", like "not traffic from port 443"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateSourceIpPort,

		## IP Port of the traffic destination, either a single IP port, or a range of IP ports. Examples:  "443" or "80-1024"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidatePattern("^\d+(-\d+)?$")][String]$DestinationIpPort,

		## Switch:  negate the destination IP port?  If $true, then this has the effect of "not destination IP port", like "not traffic to port 443"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateDestinationIpPort,

		## TCP flag. The valid values can be found at RFC 3168.
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Int]$TCPFlag,

		## Switch: negate TCP flag? If $true, then this has the effect of "not this TCP flag", like "not traffic to with given TCP flag"
		[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateTCPFlag,


		## Single MAC address or a MAC address range of the traffic source. If this parameter is omitted (or $null), it will match "any MAC address".
		#
		# The MAC address "range" is a mask that is used in matching the MAC address. A MAC address is considered matched if the "and" operation of the mask on the MAC address and address yields the same result. For example, a MAC of "00:A0:FF:14:FF:29" is considered matched for a address of "00:A0:C9:14:C8:29" and a mask of "FF:FF:00:FF:00:FF".
		#
		# Single MAC example:  00:00:56:01:23:45
		# MAC range example:  00:A0:C9:14:C8:29/FF:FF:00:FF:00:FF
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][ValidatePattern("^([a-f0-9]{2}:){5}[a-f0-9]{2}(/([a-f0-9]{2}:){5}[a-f0-9]{2})?$")][String]$SourceMacAddress,

		## Switch:  negate the source MAC address?  If $true, then this has the effect of "not source MAC", like "not traffic from 00:00:56:01:23:45"
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Switch]$NegateSourceMacAddress,

		## Single MAC address or a MAC address range of the traffic destination. If this parameter is omitted (or $null), it will match "any MAC address".
		#
		# The MAC address "range" is a mask that is used in matching the MAC address. See description of parameter -SourceMacAddress for more information.
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][ValidatePattern("^([a-f0-9]{2}:){5}[a-f0-9]{2}(/([a-f0-9]{2}:){5}[a-f0-9]{2})?$")][String]$DestinationMacAddress,

		## Switch:  negate the destination MAC address?  If $true, then this has the effect of "not destination MAC", like "not traffic to 00:00:56:01:23:45"
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Switch]$NegateDestinationMacAddress,

		## EtherType protocol used. Example: 0x8922. This corresponds to the EtherType field in Ethernet frame. The valid values can be found from IEEE list at: http://standards.ieee.org/regauth/ as mentioned in RFC 5342 (for example, in text format at http://standards-oui.ieee.org/ethertype/eth.txt).
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Int]$EtherTypeProtocol,

		## Switch: negate EtherType protocol? If $true, then this has the effect of "not this ethertype protocol", like "not traffic to using ethertype protocol 0x8922"
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Switch]$NegateEtherTypeProtocol,

		## VLAN ID for rule qualifier.
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Int]$VlanId,

		## Switch: negate VLAN ID? If $true, then this has the effect of "not this VLAN ID", like "not traffic to using VLAN ID 1234"
		[parameter(ParameterSetName="MacNetworkRuleQualifier")][Switch]$NegateVlanId
	)

	process {
		Switch ($PSCmdlet.ParameterSetName) {
			## SystemTrafficNetworkRuleQualifier
			## VMware.Vim.DvsSystemTrafficNetworkRuleQualifier, https://vdc-repo.vmware.com/vmwb-repository/dcr-public/98d63b35-d822-47fe-a87a-ddefd469df06/8212891f-77f8-4d27-ab3b-9e2fa52e5355/doc/vim.dvs.TrafficRule.SystemTrafficQualifier.html
			"SystemTrafficNetworkRuleQualifier" {
				New-Object -TypeName VMware.Vim.DvsSystemTrafficNetworkRuleQualifier -Property @{
					typeOfSystemTraffic = New-Object -Type VMware.Vim.StringExpression -Property @{
						Value = $SystemTrafficType
						Negate = $NegateSystemTrafficType
					} ## end new-object
				} ## end new-object
				break
			} ## end case


			## IpNetworkRuleQualifier
			## VMware.Vim.DvsIpNetworkRuleQualifier, https://vdc-repo.vmware.com/vmwb-repository/dcr-public/98d63b35-d822-47fe-a87a-ddefd469df06/8212891f-77f8-4d27-ab3b-9e2fa52e5355/doc/vim.dvs.TrafficRule.IpQualifier.html
			"IpNetworkRuleQualifier" {
				## hash table to hold the properties for creating a new DvsIpNetworkRuleQualifier object
				$hshPropertiesForNewDvsIpNetworkRuleQualifier = @{}

				## make source- and destination address objects with either SingleIp or IpRange objects, accordingly based on parameter provided, if provided at all
				if ($PSBoundParameters.ContainsKey("SourceIpAddress")) {
					$oSrcIpAddress = if ($SourceIpAddress -match "/") {
						$strIp, [int]$intSubnetMaskLength = $SourceIpAddress.Split("/")
						New-Object -Type VMware.Vim.IpRange -Property @{
							addressPrefix = $strIp
							prefixLength = $intSubnetMaskLength
							negate = $NegateSourceIpAddress
						} ## end new-object
					} else {New-Object -Type VMware.Vim.SingleIp -Property @{address = $SourceIpAddress; negate = $NegateSourceIpAddress}} ## end else

					$hshPropertiesForNewDvsIpNetworkRuleQualifier["sourceAddress"] = $oSrcIpAddress
				} ## end if

				if ($PSBoundParameters.ContainsKey("DestinationIpAddress")) {
					$oDestIpAddress = if ($DestinationIpAddress -match "/") {
						$strIp, [int]$intSubnetMaskLength = $DestinationIpAddress.Split("/")
						New-Object -Type VMware.Vim.IpRange -Property @{
							addressPrefix = $strIp
							prefixLength = $intSubnetMaskLength
							negate = $NegateDestinationIpAddress
						} ## end new-object
					} else {New-Object -Type VMware.Vim.SingleIp -Property @{address = $DestinationIpAddress; negate = $NegateDestinationIpAddress}} ## end else

					$hshPropertiesForNewDvsIpNetworkRuleQualifier["destinationAddress"] = $oDestIpAddress
				} ## end if

				## add other hashtable items if the given parameters were specified
				if ($PSBoundParameters.ContainsKey("Protocol")) {$hshPropertiesForNewDvsIpNetworkRuleQualifier["protocol"] = New-Object -Type VMware.Vim.IntExpression -Property @{Value = $Protocol; Negate = $NegateProtocol}}
				if ($PSBoundParameters.ContainsKey("TCPFlag")) {$hshPropertiesForNewDvsIpNetworkRuleQualifier["tcpFlags"] = New-Object -Type VMware.Vim.IntExpression -Property @{Value = $TCPFlag; Negate = $NegateTCPFlag}}

				## the Source- and Destination IPPort config items, if any
				if ($PSBoundParameters.ContainsKey("SourceIpPort")) {
					$oSrcIpPort = if ($SourceIpPort -match "-") {
						[int]$intIpPort_start, [int]$intIpPort_end = $SourceIpPort.Split("-")
						New-Object -TypeName VMware.Vim.DvsIpPortRange -Property @{
							startPortNumber = $intIpPort_start
							endPortNumber = $intIpPort_end
							negate = $NegateSourceIpPort
						} ## end new-object
					} ## end if
					else {New-Object -Type VMware.Vim.DvsSingleIpPort -Property @{portNumber = $SourceIpPort; negate = $NegateSourceIpPort}} ## end else

					$hshPropertiesForNewDvsIpNetworkRuleQualifier["sourceIpPort"] = $oSrcIpPort
				} ## end if

				if ($PSBoundParameters.ContainsKey("DestinationIpPort")) {
					$oDestIpPort = if ($DestinationIpPort -match "-") {
						[int]$intIpPort_start, [int]$intIpPort_end = $DestinationIpPort.Split("-")
						New-Object -TypeName VMware.Vim.DvsIpPortRange -Property @{
							startPortNumber = $intIpPort_start
							endPortNumber = $intIpPort_end
							negate = $NegateDestinationIpPort
						} ## end new-object
					} ## end if
					else {New-Object -Type VMware.Vim.DvsSingleIpPort -Property @{portNumber = $DestinationIpPort; negate = $NegateDestinationIpPort}} ## end else

					$hshPropertiesForNewDvsIpNetworkRuleQualifier["destinationIpPort"] = $oDestIpPort
				} ## end if

				## make the actual new object
				New-Object -TypeName VMware.Vim.DvsIpNetworkRuleQualifier -Property $hshPropertiesForNewDvsIpNetworkRuleQualifier
				break
			} ## end case


			## MacNetworkRuleQualifier
			## VMware.Vim.DvsMacNetworkRuleQualifier, https://vdc-repo.vmware.com/vmwb-repository/dcr-public/98d63b35-d822-47fe-a87a-ddefd469df06/8212891f-77f8-4d27-ab3b-9e2fa52e5355/doc/vim.dvs.TrafficRule.MacQualifier.html
			"MacNetworkRuleQualifier" {
				## hash table to hold the properties for creating a new DvsMacNetworkRuleQualifier object
				$hshPropertiesForNewDvsMacNetworkRuleQualifier = @{}

				## make source- and destination address objects with either SingleMac or MacRange objects, accordingly based on parameter provided, if provided at all
				if ($PSBoundParameters.ContainsKey("SourceMacAddress")) {
					$oSrcMacAddress = if ($SourceMacAddress -match "/") {
						$strMac, $strMacMask = $SourceMacAddress.Split("/")
						New-Object -Type VMware.Vim.MacRange -Property @{
							address = $strMac
							mask = $strMacMask
							negate = $NegateSourceMacAddress
						} ## end new-object
					} else {New-Object -Type VMware.Vim.SingleMac -Property @{address = $SourceMacAddress; negate = $NegateSourceMacAddress}} ## end else

					$hshPropertiesForNewDvsMacNetworkRuleQualifier["sourceAddress"] = $oSrcMacAddress
				} ## end if

				if ($PSBoundParameters.ContainsKey("DestinationMacAddress")) {
					$oDestMacAddress = if ($DestinationMacAddress -match "/") {
						$strMac, $strMacMask = $DestinationMacAddress.Split("/")
						New-Object -Type VMware.Vim.MacRange -Property @{
							address = $strMac
							mask = $strMacMask
							negate = $NegateDestinationMacAddress
						} ## end new-object
					} else {New-Object -Type VMware.Vim.SingleMac -Property @{address = $DestinationMacAddress; negate = $NegateDestinationMacAddress}} ## end else

					$hshPropertiesForNewDvsMacNetworkRuleQualifier["destinationAddress"] = $oDestMacAddress
				} ## end if

				## add other hashtable items if the given parameters were specified
				if ($PSBoundParameters.ContainsKey("EtherTypeProtocol")) {$hshPropertiesForNewDvsMacNetworkRuleQualifier["protocol"] = New-Object -Type VMware.Vim.IntExpression -Property @{Value = $EtherTypeProtocol; Negate = $NegateEtherTypeProtocol}}
				if ($PSBoundParameters.ContainsKey("VlanId")) {$hshPropertiesForNewDvsMacNetworkRuleQualifier["vlanId"] = New-Object -Type VMware.Vim.IntExpression -Property @{Value = $VlanId; Negate = $NegateVlanId}}

				New-Object -TypeName VMware.Vim.DvsMacNetworkRuleQualifier -Property $hshPropertiesForNewDvsMacNetworkRuleQualifier
			} ## end case
		} ## end switch
	} ## end process
} ## end function



function New-VNVDTrafficRuleAction {
<#	.Description
	Make new VMware.Vim.DvsNetworkRuleAction, for use in creating vDPortgroup traffic filter policy rule.  Currently supports creating Rule Actions of types DvsAcceptNetworkRuleAction ("Allow"), DvsDropNetworkRuleAction, and DvsUpdateTagNetworkRuleAction

	.Example
	New-VNVDTrafficRuleAction -Allow
	Create a new DvsAcceptNetworkRuleAction object that will specify an action of "Allow packet"

	.Example
	New-VNVDTrafficRuleAction -Drop
	Create a new DvsDropNetworkRuleAction object that will specify an action of "Drop packet"

	.Example
	New-VNVDTrafficRuleAction -DscpTag 8 -QosTag 0
	Create a new DvsUpdateTagNetworkRuleAction object that will specify an action of "tag with DSCP value of 8, and clear the QoS tag of packet"

	.Outputs
	VMware.Vim.DvsNetworkRuleAction
#>
	[OutputType([VMware.Vim.DvsNetworkRuleAction])]
	param (
		## Make an Accept ("Allow") rule action?
		[parameter(ParameterSetName="DvsAcceptNetworkRuleAction")][Switch]$Allow,

		## Make an Accept ("Allow") rule action?
		[parameter(ParameterSetName="DvsDropNetworkRuleAction")][Switch]$Drop,

		## DSCP tag. From the VMware API documentation: "The valid values for DSCP tag can be found in 'Differentiated Services Field Codepoints' section of IANA website. The information can also be got from reading all of the below RFC: RFC 2474, RFC 2597, RFC 3246, RFC 5865. If the dscpTag is set to 0 then the dscp tag on packets will be cleared."
		[parameter(ParameterSetName="DvsUpdateTagNetworkRuleAction")][Int]$DscpTag,

		## QoS tag. From the VMware API documentation: "IEEE 802.1p supports 3 bit Priority Code Point (PCP). The valid values are between 0-7. Please refer the IEEE 802.1p documentation for more details about what each value represents. If qosTag is set to 0 then the tag on the packets will be cleared."
		[parameter(ParameterSetName="DvsUpdateTagNetworkRuleAction")][ValidateRange(0,7)][Int]$QosTag
	)
	process {
		Switch ($PSCmdlet.ParameterSetName) {
			"DvsAcceptNetworkRuleAction" {New-Object -TypeName VMware.Vim.DvsAcceptNetworkRuleAction; break}
			"DvsDropNetworkRuleAction" {New-Object -TypeName VMware.Vim.DvsDropNetworkRuleAction; break}

			# DvsUpdateTagNetworkRuleAction, https://vdc-repo.vmware.com/vmwb-repository/dcr-public/98d63b35-d822-47fe-a87a-ddefd469df06/8212891f-77f8-4d27-ab3b-9e2fa52e5355/doc/vim.dvs.TrafficRule.UpdateTagAction.html
			"DvsUpdateTagNetworkRuleAction" {
				## hash table to hold the properties for creating a new RuleAction object
				$hshPropertiesForNewRuleAction = @{}
				if ($PSBoundParameters.ContainsKey("DscpTag")) {$hshPropertiesForNewRuleAction["dscpTag"] = $DscpTag}
				if ($PSBoundParameters.ContainsKey("QosTag")) {$hshPropertiesForNewRuleAction["qosTag"] = $QosTag}

				New-Object -TypeName VMware.Vim.DvsUpdateTagNetworkRuleAction -Property $hshPropertiesForNewRuleAction
			} ## end case
		} ## end switch
	} ## end process
} ## end function



function New-VNVDTrafficRule {
<#	.Description
	Make new Traffic Rule, for use in creating vDPortgroup traffic filter policy

	.Example
	New-VNVDTrafficRule -Name "Allow vMotion from source network" -Action (New-VNVDTrafficRuleAction -Allow) -Qualifier (New-VNVDNetworkRuleQualifier -SystemTrafficType vMotion), (New-VNVDNetworkRuleQualifier -SourceIpAddress 10.0.0.0/8)
	Create a new Traffic Rule that has two Qualifiers. The new Traffic Rule allows vMotion traffic from given source network

	.Example
	New-VNVDTrafficRule -Name "Apply DSCP tag to VM traffic from given address" -Action (New-VNVDTrafficRuleAction -DscpTag 8) -Qualifier (New-VNVDNetworkRuleQualifier -SystemTrafficType virtualMachine), (New-VNVDNetworkRuleQualifier -SourceIpAddress 172.16.1.2) -Direction outgoingPackets
	Create a new Traffic Rule that has two Qualifiers. The new Traffic Rule adds a DSCP tag with value 8 to VM traffic from given source IP

	.Outputs
	VMware.Vim.DvsTrafficRule
#>
	[CmdletBinding()]
	[OutputType([VMware.Vim.DvsTrafficRule])]
	param(
		## Name/description of the new rule
		[parameter(Mandatory=$true)][String]$Name,

		## Action to be applied for this rule. Can use New-VNVDTrafficRuleAction to create a new Action object to use for this parameter
		[parameter(Mandatory=$true)][VMware.Vim.DvsNetworkRuleAction]$Action,

		## The direction of the packets to which to apply this rule (incoming packets, outgoing packets, or both). Defaults to "both" if not specified. Current valid values are IncomingPackets, OutgoingPackets, or Both. See VMware.Vim.DvsNetworkRuleDirectionType enumeration for these valid values (like:  [System.Enum]::GetNames([VMware.Vim.DvsNetworkRuleDirectionType]))
		[VMware.Vim.DvsNetworkRuleDirectionType]$Direction = "Both",

		## One or more Rule Qualifiers to use in this rule. Can use New-VNVDNetworkRuleQualifier to create new Rule Qualifier to use as values for this parameter. More info from VMware API documentation:
		#
		# "List of Network rule qualifiers. 'AND' of this array of network rule qualifiers is applied as one network traffic rule. For TrafficRule belonging to DvsFilterPolicy: There can be a maximum of 1 DvsIpNetworkRuleQualifier, 1 DvsMacNetworkRuleQualifier and 1 DvsSystemTrafficNetworkRuleQualifier for a total of 3 qualifiers"
		[parameter(Mandatory=$true)][VMware.Vim.DvsNetworkRuleQualifier[]]$Qualifier,

		## Order in which to place this rule in a rule set.  "Sequence of this rule".
		[Int]$Sequence
	) ## end param

	begin {
		## mapping of function parameter name to new-object property name, to use in creating new object more efficiently (by iterating over the parameters passed to the function)
		$hshParameterNameToNewObjectPropertyNameMapping = @{
			Action = "action"
			Name = "description"
			Qualifier = "qualifier"
			Sequence = "sequence"
		} ## end hsh
	} ## end begin

	process {
		## always add Direction key/value is in the hsh (so that, if not specified by user, it takes default value)
		$hshParamForNewRuleObject = @{direction = $Direction}

		## for any of the other bound parameters that are for specific properties of a new Traffic Rule (i.e., that are not "common" PowerShell parameters like -Verbose or -PipelineVariable)
		$PSBoundParameters.Keys | Where-Object {$hshParameterNameToNewObjectPropertyNameMapping.ContainsKey($_)} | Foreach-Object {
			## get the new API object property name to use from the NameMapping hashtable, and set the value to that of the given bound parameter
			$hshParamForNewRuleObject[$hshParameterNameToNewObjectPropertyNameMapping[$_]] = $PSBoundParameters[$_]
		} ## end foreach-object

		New-Object -TypeName VMware.Vim.DvsTrafficRule -Property $hshParamForNewRuleObject
	} ## end process
} ## end function