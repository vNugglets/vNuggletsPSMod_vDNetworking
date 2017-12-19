<#	.Description
	Make new VMware.Vim.DvsNetworkRuleQualifier, for use in creating vDPortgroup traffic filter policy rule

	.Example
	New-NetworkRuleQualifier.ps1 -SystemTrafficType vMotion
	Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is vMotion

	.Example
	New-NetworkRuleQualifier.ps1 -SystemTrafficType Management -Negate
	Create a new DvsSystemTrafficNetworkRuleQualifier for traffic that is _not_ Management traffic

	.Example
	New-NetworkRuleQualifier.ps1 -SourceIpAddress 172.16.1.2 -DestinationIpAddress 10.0.0.0/8 -NegateDestinationIpAddress -Protocol 6 -SourceIpPort 443-444
	Create a new DvsIpNetworkRuleQualifier for traffice from the given source IP that is _not_ to the given destination network, using TCP (6) protocol, and that is from source ports of 443 or 444

	.Example
	New-NetworkRuleQualifier.ps1 -SourceMacAddress 00:00:56:01:23:45 -DestinationMacAddress 00:00:56:78:90:12 -NegateDestinationMacAddress -EtherTypeProtocol 0x8922 -VlanId 10 -NegateVlanId
	Create a new DvsMacNetworkRuleQualifier for traffic from the source MAC address, that is _not_ to the destination MAC, that is using EtherType 0x8922, and that is not on VLAN 10

	.Example
	New-NetworkRuleQualifier.ps1 -SourceMacAddress 00:A0:C9:14:C8:29/FF:FF:00:FF:00:FF -VlanId 22
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
	[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidateScript({($_ -match "^\d+(-\d+)?$")})][String]$SourceIpPort,

	## Switch:  negate the source IP port?  If $true, then this has the effect of "not source IP port", like "not traffic from port 443"
	[parameter(ParameterSetName="IpNetworkRuleQualifier")][Switch]$NegateSourceIpPort,

	## IP Port of the traffic destination, either a single IP port, or a range of IP ports. Examples:  "443" or "80-1024"
	[parameter(ParameterSetName="IpNetworkRuleQualifier")][ValidateScript({($_ -match "^\d+(-\d+)?$")})][String]$DestinationIpPort,

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
