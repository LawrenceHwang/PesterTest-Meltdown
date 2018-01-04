# PesterTest-Meltdown
This is a pester test for speculative execution side-channel vulnerabilities on windows

## Synopsis
   This is a pester test for speculative execution side-channel vulnerabilities.
## DESCRIPTION
   The pester test leverages the Get-SpeculationControlSettings released by Microsoft for validating the settings related to the speculative execution side-channel vulnerabilities. It is possible to run this test against multiple machines. The test assumes:
  - It is executed from an account already has access to the target machines
  - PowerShell remoting is available and working.

## EXAMPLE
```
    Invoke-Pester -Script @{path = 'C:\Meltdown.tests.ps1'; parameters = @{ComputerName = 'demo-machine'}}
    Describing Meltdown compliance for demo-machine
       Context demo-machine - CVE-2017-5715 [branch target injection]
        [-] Hardware support for branch target injection mitigation should be present 2.66s
          Expected: {True}
          But was:  {False}
          256:                 $Result.BTIHardwarePresent | Should be $true
          at <ScriptBlock>, C:\Meltdown.tests.ps1: line 256
        [-] Windows OS support for branch target injection mitigation should be present 41ms
          Expected: {True}
          But was:  {False}
          259:                 $Result.BTIWindowsSupportPresent | Should be $true
          at <ScriptBlock>, C:\Meltdown.tests.ps1: line 259
        [-] Windows OS support for branch target injection mitigation should be enabled 41ms
          Expected: {True}
          But was:  {False}
          262:                 $Result.BTIWindowsSupportEnabled | Should be $true
          at <ScriptBlock>, C:\Meltdown.tests.ps1: line 262
       Context demo-machine - CVE-2017-5754 [rogue data cache load]
        [-] Windows OS support for kernel VA shadow should be present 64ms
          Expected: {True}
          But was:  {False}
          269:                     $Result.KVAShadowWindowsSupportPresent | Should be $true
          at <ScriptBlock>, C:\Meltdown.tests.ps1: line 269
        [-] Windows OS support for kernel VA shadow should be enabled 40ms
          Expected: {True}
          But was:  {False}
          272:                     $Result.KVAShadowWindowsSupportEnabled | Should be $true
          at <ScriptBlock>, C:\Meltdown.tests.ps1: line 272
    Tests completed in 2.84s
    Passed: 0 Failed: 5 Skipped: 0 Pending: 0 Inconclusive: 0
```

## NOTES
The Get-SpeculationControlSettings function is originated and credited to Microsoft Security Response Center.
https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution

## Disclaimer:
Use at own risk. Keep the assumed breach mindset. =)
