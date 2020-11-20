# vNugglets.VDNetworking PowerShell Module for VMware vSphere Virtual Distributed Networking Management
[![PSGallery Version](https://img.shields.io/powershellgallery/v/vNugglets.VDNetworking.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/vNugglets.VDNetworking) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/vNugglets.VDNetworking.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/vNugglets.VDNetworking)

Contents:

- [QuickStart](#quickStart)
- [Examples](#examplesSection)
- [Getting Help](#gettingHelpSection)
- [ChangeLog](#changelog)

This PowerShell module provides functionality to automate the management of VMware vSphere virtual distributed networking items for which VMware PowerCLI does not already provide support.  For example, for the reporting on-, creation of-, and removal of traffic filtering and marking rules at the vDPortgroup level.  Another capability:  managing the VDUplink of which a VMHost VMNIC is a part.

Some of the functionality provided by the cmdlets in this module:
- Get VDPortgroup and VDPort traffic policy
- Get traffic policy rules
- Get traffic policy rule qualifiers
- Create traffic policy rule qualifiers, for use in creation of new policy rules
- Create new traffic rules for the ruleset for the given vDPortgroup or vDPort
- Remove given traffic rule(s) from a vDPortgroup or vDPort
- Set the VDSwitch Uplink for a VMHost physical NIC ("VMNIC") on the VDSwitch of which the VMNIC is already a part

<a id="quickStart"></a>
### QuickStart
Chomping at the bit to get going with using this module? Of course you are! Go like this:
- This module available in the PowerShell Gallery! To install it on your machine or to save it for inspection, first, use one of these:
  - Install the module (maybe after you've inspected it first with the command after this):

      `Find-Module vNugglets.VDNetworking | Install-Module`
  - Or, save the module first for further inspection/distribution (always a good idea):

      `Find-Module vNugglets.VDNetworking | Save-Module -Path c:\temp\someFolder`

<a id="examplesSection"></a>
### Examples
Examples are in two places:
  - periodically updated in the docs/ folder for the project at [docs/examples.md](docs/examples.md), which is also accessible via the project's [GitHub Pages examples page](https://vnugglets.github.io/vNuggletsPSMod_vDNetworking/examples.html)
  - always up to date in the `Get-Help` examples for each cmdlet by checking out the help for each cmdlet (see [Getting Help](#gettingHelpSection) section below)

<a id="gettingHelpSection"></a>
### Getting Help
The cmdlets in this module all have proper help, so you can learn and discover just as you would and do with any other legitimate PowerShell module:
- `Get-Command -Module <moduleName>`
- `Get-Help -Full <cmdlet-name>`

<a id="changelog"></a>
### ChangeLog
The [ChangeLog](ChangeLog.md) for this module is, of course, a log of the major changes through the module's history.  Enjoy the story.

### Other
If you are not interested in- or able to use the PowerShell Gallery, you can get the module in this way:
- clone the GitHub project to some local folder with Git via:
  ```PowerShell
  PS C:\> git clone https://github.com/vNugglets/vNuggletsPSMod_vDNetworking.git C:\temp\MyVNuggsVDRepoCopy
  ```
- put the actual PowerShell module directory in some place that you like to keep your modules, say, like this, which copies the module to your personal Modules directory:
  ```PowerShell
  PS C:\> Copy-Item -Recurse -Path C:\temp\MyVNuggsVDRepoCopy\vNugglets.VDNetworking\ -Destination ~\Documents\WindowsPowerShell\Modules\vNugglets.VDNetworking
  ```
- import the PowerShell module into the current PowerShell session:
  ```PowerShell
  PS C:\> Import-Module -Name vNugglets.VDNetworking
  ```
- or, if the vNugglets.VDNetworking module folder is not in your `Env:\PSModulePath`, specify the whole path to the module folder when importing, like:
  ```PowerShell
  PS C:\> Import-Module -Name \\myserver.dom.com\PSModules\vNugglets.VDNetworking
  ```
