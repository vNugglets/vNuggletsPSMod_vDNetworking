## some code to put the cmdlets' examples into MD format for, say, examples.md in the docs

"### Examples for vNugglets.VDNetworking PowerShell module for VMware vSphere Virtual Distributed Networking management`n"
Get-Command -Module vNugglets.VDNetworking -PipelineVariable oThisCommand | Foreach-Object {
	## get the full help for this cmdlet
	$oHelp_ThisCommand = Get-Help -Full -Name $oThisCommand.Name
	## make a string with the example description(s) and example code(s) for this cmdlet
	$strExampleCodeBlock = ($oHelp_ThisCommand.examples.example | Foreach-Object {
		## for this example, make a single string that is like:
		#   ## example's comment line 0 here
		#   ## example's comment line 1 here
		#   example's actual code here
		"`n{0}`n{1}" -f ($($_.remarks.Text | Where-Object {-not [System.String]::IsNullOrEmpty($_)} | Foreach-Object {$_.Split("`n")} | Foreach-Object {"## $_"}) -join "`n"), $_.code
	}) -join "`n"
	## make a string that has the cmdlet name and description followed by a code block with example(s)
	"#### ``{0}``: {1}`n`n``````PowerShell{2}`n```````n" -f `
		$oThisCommand.Name,
		$oHelp_ThisCommand.Description.Text,
		$strExampleCodeBlock
} ## end Foreach-Object