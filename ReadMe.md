# vNugglets PowerShell Module for VMware vSphere Virtual Distributed Networking Management
Contents:

- [QuickStart](#quickStart)
- [Examples](#examplesSection)
- [Getting Help](#gettingHelpSection)
- [ChangeLog](#changelog)

This is a PowerShell module created for providing functionality to automate the management of VMware vSphere virtual distributed networking items for which VMware PowerCLI does not already provide support.  For example, for the reporting on- and creation of traffic filtering and marking at the vDPortgroup level.

Some of the functionality provided by the cmdlets in this module:
- Get VDPortgroup traffic policy
- Get traffic policy rules
- Get traffic policy rule qualifiers
- Create traffic policy rule qualifiers, for use in creation of new policy rules

<a id="quickStart"></a>
### QuickStart
Chomping at the bit to get going with using this module? Of course you are! Go like this:
- Eventually, we'll have this module available in the PowerShell Gallery, but for now: clone the GitHub project to some local folder with Git via:
  `PS C:\> git clone https://github.com/vNugglets/vNuggletsPSMod_vDNetworking.git C:\temp\MyVNuggsVDRepoCopy`
- put the actual PowerShell module directory in some place that you like to keep your modules, say, like this, which copies the module to your personal Modules directory:
  `PS C:\> Copy-Item -Recurse -Path C:\temp\MyVNuggsVDRepoCopy\vNugglets.VDNetworking\ -Destination ~\Documents\WindowsPowerShell\Modules\vNugglets.VDNetworking`
- import the PowerShell module into the current PowerShell session:
  `PS C:\> Import-Module -Name vNugglets.VDNetworking`
  or, if the vNugglets.VDNetworking module folder is not in your `Env:\PSModulePath`, specify the whole path to the module folder, like:
  `PS C:\> Import-Module -Name \\myserver.dom.com\PSModules\vNugglets.VDNetworking`

<a id="examplesSection"></a>
### Examples
Examples are forthcoming on the web, but you can always check out the examples for each cmdlet by checking out the help for each cmdlet (see [Getting Help](#gettingHelpSection) section below)

<a id="gettingHelpSection"></a>
### Getting Help
The cmdlets in this module all have proper help, so you can learn and discover just as you would and do with any other legitimate PowerShell module:
- `Get-Command -Module <moduleName>`
- `Get-Help -Full <cmdlet-name>`

<a id="changelog"></a>
### ChangeLog
The [ChangeLog](ChangeLog.md) for this module is, of course, a log of the major changes through the module's hitory.  Enjoy the story.

### Other Notes
A few notes on updates to this repo:

Dec 2017
- initial public dev release
