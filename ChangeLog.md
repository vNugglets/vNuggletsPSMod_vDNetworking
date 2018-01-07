### ChangeLog for vNugglets.VDNetworking PowerShell module

#### v1.0.next, Sometime 2018
- \[update] Added `-WhatIf` support to `New-VNVDTrafficRuleAction`, `New-VNVDTrafficRuleQualifier`
- \[bugfix] `-Enabled` parameter on `Set-VNVDTrafficRuleSet` was not working as expected. Fixed
- \[bugfix] Corrected issue where module loaded improperly if required VDS module was not already loaded
- \[enhancement] Added check in ModuleManifest update code to report FileList accuracy every time
- \[miscellaneous] Other various updates and optimizations

#### v1.0, Jan 2018
- initial public "prod" release of `master` branch
- published module in PowerShell Gallery

#### v0.5, under development in Dec 2017
