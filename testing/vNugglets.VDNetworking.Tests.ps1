<#  .Description
    Pester tests for vNugglets.VDNetworking PowerShell module.  Expects that:
    0) vNugglets.VDNetworking module is already loaded (but, will try to load it if not)
    1) a connection to at least one vCenter is in place (but, will prompt for vCenter to which to connect if not)

    .Example
    Invoke-Pester -Script @{Path = '\\some\path\vNuggletsPSMod_VDNetworking\testing\vNugglets.VDNetworking.Tests_Get.ps1'; Parameters = @{Datacenter = "myFavoriteDatacenter"}}
    Invokes the tests in said Tests script, passing the given Datacenter parameter value, to be used for the cluster-specific tests
#>

## initialize things, preparing for tests
$oDatacenterToUse = & $PSScriptRoot\vNugglets.VDNetworking.TestingInit.ps1 -Datacenter $Datacenter
$strGuidForThisTest = (New-Guid).Guid

## create a new VDSwitch on which to test
$oTestVDSwitch = New-VDSwitch -Name "vNuggsTestVDS_toDelete_${strGuidForThisTest}" -Location $oDatacenterToUse -Verbose

## create a new vDPortgroup
$oTestVDPG = New-VDPortgroup -VDSwitch $oTestVDSwitch -Name "vNuggsTestVDPG_toDelete_${strGuidForThisTest}" -Notes "testing vDPG" -Verbose

## allow to config TrafficFilter on vDPort
$specDVPortgroupConfigSpec = New-Object -Type VMware.Vim.DVPortgroupConfigSpec -Property @{
    ConfigVersion = $oTestVDPG.ExtensionData.Config.ConfigVersion
    Policy        = $oTestVDPG.ExtensionData.Config.Policy
} ## end new-object
$specDVPortgroupConfigSpec.Policy.TrafficFilterOverrideAllowed = $true
$oTestVDPG.ExtensionData.ReconfigureDVPortgroup($specDVPortgroupConfigSpec)

## get first vDPort
$oTestVDP = Get-VDPort -VDPortgroup $oTestVDPG | Select-Object -First 1
$oTestVDP2 = Get-VDPort -VDPortgroup $oTestVDPG | Select-Object -First 1 -Skip 1

# Fill the Testcases with the values
$TestCasesVDP = @()
$TestCasesVDPG = @()
$TestCasesAll = @()
# $oTestVDP | ForEach-Object { $TestCasesAll += @{oTestVDthing = $_} }
$oTestVDPG | ForEach-Object { $TestCasesVDPG += @{oTestVDthing = $_} }
$oTestVDP | ForEach-Object { $TestCasesVDP += @{oTestVDthing = $_} }
$oTestVDP, $oTestVDPG, $oTestVDP2 | ForEach-Object { $TestCasesAll += @{oTestVDthing = $_} }

Describe 'vNuggletsVDNetworking' {
    Context "vDPort" -Tag "vDPort" {
        It "get Traffic Fileter Policy config - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDthing | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
            $oTestVDTrafficFilterPolicyConfig | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig | Should -BeOfType "VNVDTrafficFilterPolicyConfig"
            $oTestVDTrafficFilterPolicyConfig.Count | Should -Be 1
            $oTestVDTrafficFilterPolicyConfig.TrafficFilterPolicyConfig | Should -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should be disabled) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.VDPortView | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.TrafficRulesetEnabled | Should -BeFalse
        } ## end It

        It "get TrafficRule (should be 0) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule | Should -BeNullOrEmpty
        } ## end It
        
        It "Override FilterConfig on Port - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Override:$true -Confirm:$false
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
            $oTestVDTrafficFilterPolicyConfig.TrafficFilterPolicyConfig.Inherited | Should -BeFalse
        } ## end It

        It "create three TrafficRules - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $strTestSuffix = "_$($oTestVDthing.Key)"

            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule0_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -Allow) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType faultTolerance -NegateSystemTrafficType), (New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.10.0/24 -DestinationIpAddress 10.0.0.0/8 -SourceIpPort 443-444)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule1_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 5 -DscpTag 23) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vsan)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule2_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 7 -DscpTag 30) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vdp), (New-VNVDTrafficRuleQualifier -DestinationIpAddress 172.16.100.0/24)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should have three TrafficRules) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 3
        } ## end It

        It "enable the TrafficRuleSet - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled -Confirm:$false
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
        } ## end It

        It "get TrafficRules (should be three) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule.Count | Should -Be 3
        } ## end It

        It "remove two TrafficRules - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Select-Object -Last 2 | Remove-VNVDTrafficRule -Confirm:$false
            $oTestVDTrafficRule | Should -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should have one TrafficRule) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 1
        } ## end It

        It "get TrafficRules (should be one) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule.Count | Should -Be 1
        } ## end It

        It "Remove Override FilterConfig on Port - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Override:$false -Confirm:$false
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
            $oTestVDTrafficFilterPolicyConfig.Count | Should -Be 1
            $oTestVDTrafficFilterPolicyConfig.TrafficFilterPolicyConfig | Should -BeNullOrEmpty
        } ## end It

        It "get TrafficRules (should be 0) - <oTestVDthing>" -TestCases $TestCasesVDP {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule.Count | Should -Be 0
        } ## end It
    } ## end Context

    Context "vDPortgroup" -Tag "vDPortgroup" {
        It "get Traffic Fileter Policy config - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDthing | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
            $oTestVDTrafficFilterPolicyConfig | Should -Not -BeNullOrEmpty
            $oTestVDTrafficFilterPolicyConfig | Should -BeOfType "VNVDTrafficFilterPolicyConfig"
            $oTestVDTrafficFilterPolicyConfig.Count | Should -Be 1
            $oTestVDTrafficFilterPolicyConfig.TrafficFilterPolicyConfig | Should -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should be disabled) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.VDPortgroupView | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.TrafficRulesetEnabled | Should -BeFalse
        } ## end It

        It "get TrafficRule (should be 0) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule | Should -BeNullOrEmpty
        } ## end It

        It "create three TrafficRules - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule0_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -Allow) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType faultTolerance -NegateSystemTrafficType), (New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.10.0/24 -DestinationIpAddress 10.0.0.0/8 -SourceIpPort 443-444)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule1_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 5 -DscpTag 23) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vsan)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule2_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 7 -DscpTag 30) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vdp), (New-VNVDTrafficRuleQualifier -DestinationIpAddress 172.16.100.0/24)
            $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should have three TrafficRules) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
            $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 3
        } ## end It

        It "enable the TrafficRuleSet - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled -Confirm:$false
            $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
        } ## end It

        It "get TrafficRules (should be three) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule.Count | Should -Be 3
        } ## end It

        It "remove two TrafficRules - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Select-Object -Last 2 | Remove-VNVDTrafficRule -Confirm:$false
            $oTestVDTrafficRule | Should -BeNullOrEmpty
        } ## end It

        It "get TrafficRuleSet (should have one TrafficRule) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
            $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 1
        } ## end It

        It "get TrafficRules (should be one) - <oTestVDthing>" -TestCases $TestCasesVDPG {
            Param($oTestVDthing)
            $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
            $oTestVDTrafficRule.Count | Should -Be 1
        } ## end It
    } ## end Context

    ## Do not configure portgroup to prevent a destroyed config
    ## (you can also destroy the congig without code in the WebUI...)
    # Context "vDPortgroup and vDPorts mixed" -Tag "Mix" -Skip {
    #     It "get Traffic Fileter Policy config - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDthing | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
    #         $oTestVDTrafficFilterPolicyConfig | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficFilterPolicyConfig | Should -BeOfType "VNVDTrafficFilterPolicyConfig"
    #     } ## end It

    #     It "get TrafficRuleSet (should be disabled) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
    #         $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
    #         # $oTestVDTrafficRuleSet.VDPortgroupView | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficRuleSet.TrafficRulesetEnabled | Should -BeFalse
    #     } ## end It

    #     It "get TrafficRule (should be 0) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
    #         $oTestVDTrafficRule | Should -BeNullOrEmpty
    #     } ## end It

    #     It "create three TrafficRules - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         if ($oTestVDthing.GetType().Name -eq "VDPortImpl") {
    #             $strTestSuffix = "_$($oTestVDthing.Key)"
    #             $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Override:$true -Confirm:$false
    #             $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
    #             $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Remove-VNVDTrafficRule -Confirm:$false
    #         }
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule0_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -Allow) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType faultTolerance -NegateSystemTrafficType), (New-VNVDTrafficRuleQualifier -SourceIpAddress 172.16.10.0/24 -DestinationIpAddress 10.0.0.0/8 -SourceIpPort 443-444)
    #         $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule1_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 5 -DscpTag 23) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vsan)
    #         $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | New-VNVDTrafficRule -Name "testRule2_toDelete${strTestSuffix}" -Action (New-VNVDTrafficRuleAction -QosTag 7 -DscpTag 30) -Direction both -Qualifier (New-VNVDTrafficRuleQualifier -SystemTrafficType vdp), (New-VNVDTrafficRuleQualifier -DestinationIpAddress 172.16.100.0/24)
    #         $oTestVDTrafficRule | Should -Not -BeNullOrEmpty
    #     } ## end It

    #     It "get Override of Ports - <oTestVDthing>" -TestCases $TestCasesVDP {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficFilterPolicyConfig = $oTestVDthing | Get-VNVDTrafficFilterPolicyConfig
    #         $oTestVDTrafficFilterPolicyConfig.TrafficFilterPolicyConfig.Inherited | Should -BeFalse
    #     } ## end It

    #     It "get TrafficRuleSet (should have three TrafficRules) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
    #         $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
    #         $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 3
    #     } ## end It

    #     It "enable the TrafficRuleSet - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet | Set-VNVDTrafficRuleSet -Enabled -Confirm:$false
    #         $oTestVDTrafficRuleSet | Should -Not -BeNullOrEmpty
    #     } ## end It

    #     It "get TrafficRules (should be three) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
    #         $oTestVDTrafficRule.Count | Should -Be 3
    #     } ## end It

    #     It "remove two TrafficRules - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule | Select-Object -Last 2 | Remove-VNVDTrafficRule -Confirm:$false
    #         $oTestVDTrafficRule | Should -BeNullOrEmpty
    #     } ## end It

    #     It "get TrafficRuleSet (should have one TrafficRule) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRuleSet = $oTestVDthing | Get-VNVDTrafficRuleSet
    #         $oTestVDTrafficRuleSet.NumTrafficRule | Should -Be 1
    #     } ## end It

    #     It "get TrafficRules (should be one) - <oTestVDthing>" -TestCases $TestCasesAll {
    #         Param($oTestVDthing)
    #         $oTestVDTrafficRule = $oTestVDthing | Get-VNVDTrafficRuleSet | Get-VNVDTrafficRule
    #         $oTestVDTrafficRule.Count | Should -Be 1
    #     } ## end It
    # } ## end Context
    
    Context "CleanUp" -Tag "CleanUp" {
        It "get TrafficRules (should be one) - <oTestVDthing>" -TestCases $TestCasesVDPG -Tag "CleanUp" {
            Param($oTestVDthing)
            $oTestVDthing.VDSwitch | Remove-VDSwitch -Confirm:$false -Verbose
        } ## end It
    } ## end Context

} ## end Describe

