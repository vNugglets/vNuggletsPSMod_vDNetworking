<#  .Description
    Pester tests for vNugglets.VDNetworking PowerShell module.  Expects that:
    0) vNugglets.VDNetworking module is already loaded (but, will try to load it if not)
    1) a connection to at least one vCenter is in place (but, will prompt for vCenter to which to connect if not)

    .Example
    Invoke-Pester -Script @{Path = '\\some\path\vNuggletsPSMod_VDNetworking\testing\vNugglets.VDNetworking.Tests_Get.ps1'; Parameters = @{Datacenter = "myFavoriteDatacenter"}}
    Invokes the tests in said Tests script, passing the given Datacenter parameter value, to be used for the cluster-specific tests
#>
param (
    ## Name of the vCenter cluster to use in the vNugglets.VDNetworking testing
    [parameter(Mandatory=$true)][string]$Datacenter
)

## initialize things, preparing for tests
$oDatacenterToUse = & $PSScriptRoot\vNugglets.VDNetworking.TestingInit.ps1 -Datacenter $Datacenter
$strGuidForThisTest = (New-Guid).Guid

## create a new VDSwitch on which to test
$oTestVDSwitch = New-VDSwitch -Name "vNuggsTestVDS_toDelete_${strGuidForThisTest}" -Location $oDatacenterToUse -Verbose

## create a new vDPortgroup
$oTestVDPG = New-VDPortgroup -VDSwitch $oTestVDSwitch -Name "vNuggsTestVDPG_toDelete_${strGuidForThisTest}" -Notes "testing vDPG" -Verbose

<# tests
    - get Traffic Fileter Policy config
        $oTestVDPG | Get-VNVDTrafficFilterPolicyConfig
    - get TrafficRuleSet (should be disabled)
        $oTestVDPG | Get-VNVDTrafficRuleSet
    - get TrafficRule (should be 0)
        $oTestVDPG | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
    - create three TrafficRules
        $oTestVDPG | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule0_toDelete_${strGuidForThisTest}" -Action (New-VNVDTrafficRuleAction -Allow) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType faultTolerance -NegateSystemTrafficType), (New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.10.0/24 -DestinationIpAddress 10.0.0.0/8 -SourceIpPort 443-444)
        $oTestVDPG | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule1_toDelete_${strGuidForThisTest}" -Action (New-VNVDTrafficRuleAction -QosTag 5 -DscpTag 23) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vsan)
        $oTestVDPG | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule2_toDelete_${strGuidForThisTest}" -Action (New-VNVDTrafficRuleAction -QosTag 7 -DscpTag 30) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vdp), (New-VNVDTrafficRuleQualifier -DestinationIpAddress 172.16.100.0/24)
    - get TrafficRuleSet (should have three TrafficRules)
        $oTestVDPG | Get-VNVDTrafficRuleSet
    - enable the TrafficRuleSet
        $oTestVDPG | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled
    - get TrafficRules (should be three)
        $oTestVDPG | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Measure-Object
    - remove two TrafficRules
        $oTestVDPG | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Select-Object -Last 2 | Remove-VNVDTrafficRule
    - get TrafficRuleSet (should have one TrafficRule)
        $oTestVDPG | Get-VNVDTrafficRuleSet
    - get TrafficRules (should be one)
        $oTestVDPG | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Measure-Object
#>

## remove the VDSwitch when done
$oTestVDSwitch | Remove-VDSwitch -Verbose
