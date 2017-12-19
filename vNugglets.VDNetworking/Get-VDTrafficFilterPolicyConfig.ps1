<#	.Description
	Function to get the VDTrafficFilterPolicy configuration for the given VDPortgroup(s) from VDSwitch(es).

	.Example
	Get-VDSwitch -Name myVDSw0 | Get-VDPortGroup -Name myVDPG0 | Get-VDTrafficFilterPolicyConfig.ps1

	.Outputs
	Selected.VMware.Vim.DvsTrafficFilterConfig
#>
[CmdletBinding()]
[OutputType([VMware.Vim.DvsTrafficFilterConfig])]
param (
	## The virtual distributed portgroup for which to get the traffic filtering and marking policy configuration
	[parameter(Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Vds.Types.V1.VmwareVDPortgroup[]]$VDPortgroup
) ## end param

process {
	$VDPortgroup | Foreach-Object {
		$_.ExtensionData.Config.DefaultPortConfig.FilterPolicy.FilterConfig | Select-Object -Property *, @{n="Enabled"; e={$_.TrafficRuleset.Enabled}}
	} ## end foreach-object
} ## end process


## get VDTrafficFilterPolicyConfig:
#$viewVDPG.Config.DefaultPortConfig.FilterPolicy.FilterConfig
## can get:
# VDTrafficFilterPolicyConfig:  Key, Enabled, Precedence, Key, AgentName, SlotNumber, Parameters, OnFailure, Inherited
# --> VDTrafficFilterPolicyConfig.VDTrafficRule: Key, Description, Sequence, Qualifier, Action, Direction
# --> VDTrafficFilterPolicyConfig.VDTrafficRule.VDTrafficRuleQualifier:  VMware.Vim.DvsSystemTrafficNetworkRuleQualifier or VMware.Vim.DvsIpNetworkRuleQualifier or one other
<#
{
  "FilterConfig":  [
             {
               "TrafficRuleset":  {
                          "Key":  "51_255_ _13461229",
                          "Enabled":  true,
                          "Precedence":  null,
                          "Rules":  [
                                  {
                                    "Key":  "51_255_ _13461229_71622573",
                                    "Description":  "test VSAN rule0",
                                    "Sequence":  10,
                                    "Qualifier":  [
                                            {
                                              "TypeOfSystemTraffic":  {
                                                            "Value":  "vsan",
                                                            "Negate":  false
                                                          },
                                              "Key":  "51_255_ _13461229_71622573_99129637"
                                            }
                                          ],
                                    "Action":  {
                                           "QosTag":  null,
                                           "DscpTag":  25
                                         },
                                    "Direction":  "incomingPackets"
                                  },
                                  {
                                    "Key":  "51_255_ _13461229_16439589",
                                    "Description":  "test BUR rule",
                                    "Sequence":  20,
                                    "Qualifier":  [
                                            {
                                              "SourceAddress":  {
                                                          "AddressPrefix":  "255.255.255.255",
                                                          "PrefixLength":  0,
                                                          "Negate":  null
                                                        },
                                              "DestinationAddress":  {
                                                             "AddressPrefix":  "10.5.64.0",
                                                             "PrefixLength":  20,
                                                             "Negate":  false
                                                           },
                                              "Protocol":  {
                                                       "Value":  6,
                                                       "Negate":  false
                                                     },
                                              "SourceIpPort":  null,
                                              "DestinationIpPort":  null,
                                              "TcpFlags":  null,
                                              "Key":  "51_255_ _13461229_16439589_25543994"
                                            }
                                          ],
                                    "Action":  {
                                           "QosTag":  null,
                                           "DscpTag":  8
                                         },
                                    "Direction":  "incomingPackets"
                                  }
                                ]
                        },
               "Key":  "51_255_ _91108317",
               "AgentName":  "dvfilter-generic-vmware",
               "SlotNumber":  null,
               "Parameters":  null,
               "OnFailure":  null,
               "Inherited":  false
             }
           ],
  "Inherited":  false
}
#>