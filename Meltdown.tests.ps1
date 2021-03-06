<#
.Synopsis
   This is a pester test for speculative execution side-channel vulnerabilities.
.DESCRIPTION
   The pester test leverages the Get-SpeculationControlSettings released by Microsoft for validating the settings related to the speculative execution side-channel vulnerabilities.
   It is possoble to run this test against multiple machines.
   The test assumes:
      - It is executed from an account already has access to the target machines
      - PowerShell remoting is available and working.
.EXAMPLE
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

.NOTES
    The Get-SpeculationControlSettings function is originated and credited to Microsoft Security Response Center.
    https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution
    Disclaimer:
    Use at own risk.
#>
param(
    # Computer name(s)
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName
)
Function Get-SpeculationControlSettings
{
    <#

  .SYNOPSIS
  This function queries the speculation control settings for the system.

  .DESCRIPTION
  This function queries the speculation control settings for the system.

  Version 1.3.

  #>

    [CmdletBinding()]
    param (

    )

    process
    {

        $NtQSIDefinition = @'
    [DllImport("ntdll.dll")]
    public static extern int NtQuerySystemInformation(uint systemInformationClass, IntPtr systemInformation, uint systemInformationLength, IntPtr returnLength);
'@

        $ntdll = Add-Type -MemberDefinition $NtQSIDefinition -Name 'ntdll' -Namespace 'Win32' -PassThru


        [System.IntPtr]$systemInformationPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [System.IntPtr]$returnLengthPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)

        $object = New-Object -TypeName PSObject

        try
        {

            #
            # Query branch target injection information.
            #

            # Write-Host "Speculation control settings for CVE-2017-5715 [branch target injection]" -ForegroundColor Cyan
            # Write-Host

            $btiHardwarePresent = $false
            $btiWindowsSupportPresent = $false
            $btiWindowsSupportEnabled = $false
            $btiDisabledBySystemPolicy = $false
            $btiDisabledByNoHardwareSupport = $false

            [System.UInt32]$systemInformationClass = 201
            [System.UInt32]$systemInformationLength = 4

            $retval = $ntdll::NtQuerySystemInformation($systemInformationClass, $systemInformationPtr, $systemInformationLength, $returnLengthPtr)

            if ($retval -eq 0xc0000003)
            {
                # fallthrough
            }
            elseif ($retval -ne 0)
            {
                throw (("Querying branch target injection information failed with error {0:X8}" -f $retval))
            }
            else
            {

                [System.UInt32]$scfBpbEnabled = 0x01
                [System.UInt32]$scfBpbDisabledSystemPolicy = 0x02
                [System.UInt32]$scfBpbDisabledNoHardwareSupport = 0x04
                [System.UInt32]$scfHwReg1Enumerated = 0x08
                [System.UInt32]$scfHwReg2Enumerated = 0x10
                [System.UInt32]$scfHwMode1Present = 0x20
                [System.UInt32]$scfHwMode2Present = 0x40
                [System.UInt32]$scfSmepPresent = 0x80

                [System.UInt32]$flags = [System.UInt32][System.Runtime.InteropServices.Marshal]::ReadInt32($systemInformationPtr)

                $btiHardwarePresent = ((($flags -band $scfHwReg1Enumerated) -ne 0) -or (($flags -band $scfHwReg2Enumerated)))
                $btiWindowsSupportPresent = $true
                $btiWindowsSupportEnabled = (($flags -band $scfBpbEnabled) -ne 0)

                if ($btiWindowsSupportEnabled -eq $false)
                {
                    $btiDisabledBySystemPolicy = (($flags -band $scfBpbDisabledSystemPolicy) -ne 0)
                    $btiDisabledByNoHardwareSupport = (($flags -band $scfBpbDisabledNoHardwareSupport) -ne 0)
                }

                if ($PSBoundParameters['Verbose'])
                {
                    # Write-Host "BpbEnabled                   :" (($flags -band $scfBpbEnabled) -ne 0)
                    # Write-Host "BpbDisabledSystemPolicy      :" (($flags -band $scfBpbDisabledSystemPolicy) -ne 0)
                    # Write-Host "BpbDisabledNoHardwareSupport :" (($flags -band $scfBpbDisabledNoHardwareSupport) -ne 0)
                    # Write-Host "HwReg1Enumerated             :" (($flags -band $scfHwReg1Enumerated) -ne 0)
                    # Write-Host "HwReg2Enumerated             :" (($flags -band $scfHwReg2Enumerated) -ne 0)
                    # Write-Host "HwMode1Present               :" (($flags -band $scfHwMode1Present) -ne 0)
                    # Write-Host "HwMode2Present               :" (($flags -band $scfHwMode2Present) -ne 0)
                    # Write-Host "SmepPresent                  :" (($flags -band $scfSmepPresent) -ne 0)
                }
            }

            # Write-Host "Hardware support for branch target injection mitigation is present:"($btiHardwarePresent) -ForegroundColor $(If ($btiHardwarePresent) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })
            # Write-Host "Windows OS support for branch target injection mitigation is present:"($btiWindowsSupportPresent) -ForegroundColor $(If ($btiWindowsSupportPresent) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })
            # Write-Host "Windows OS support for branch target injection mitigation is enabled:"($btiWindowsSupportEnabled) -ForegroundColor $(If ($btiWindowsSupportEnabled) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })

            if ($btiWindowsSupportPresent -eq $true -and $btiWindowsSupportEnabled -eq $false)
            {
                # Write-Host -ForegroundColor Red "Windows OS support for branch target injection mitigation is disabled by system policy:"($btiDisabledBySystemPolicy)
                # Write-Host -ForegroundColor Red "Windows OS support for branch target injection mitigation is disabled by absence of hardware support:"($btiDisabledByNoHardwareSupport)
            }

            $object | Add-Member -MemberType NoteProperty -Name BTIHardwarePresent -Value $btiHardwarePresent
            $object | Add-Member -MemberType NoteProperty -Name BTIWindowsSupportPresent -Value $btiWindowsSupportPresent
            $object | Add-Member -MemberType NoteProperty -Name BTIWindowsSupportEnabled -Value $btiWindowsSupportEnabled
            $object | Add-Member -MemberType NoteProperty -Name BTIDisabledBySystemPolicy -Value $btiDisabledBySystemPolicy
            $object | Add-Member -MemberType NoteProperty -Name BTIDisabledByNoHardwareSupport -Value $btiDisabledByNoHardwareSupport

            #
            # Query kernel VA shadow information.
            #

            # Write-Host
            # Write-Host "Speculation control settings for CVE-2017-5754 [rogue data cache load]" -ForegroundColor Cyan
            # Write-Host

            $kvaShadowRequired = $true
            $kvaShadowPresent = $false
            $kvaShadowEnabled = $false
            $kvaShadowPcidEnabled = $false

            $cpu = Get-WmiObject Win32_Processor

            if ($cpu.Manufacturer -eq "AuthenticAMD")
            {
                $kvaShadowRequired = $false
            }
            elseif ($cpu.Manufacturer -eq "GenuineIntel")
            {
                $regex = [regex]'Family (\d+) Model (\d+) Stepping (\d+)'
                $result = $regex.Match($cpu.Description)

                if ($result.Success)
                {
                    $family = [System.UInt32]$result.Groups[1].Value
                    $model = [System.UInt32]$result.Groups[2].Value
                    $stepping = [System.UInt32]$result.Groups[3].Value

                    if (($family -eq 0x6) -and
                        (($model -eq 0x1c) -or
                            ($model -eq 0x26) -or
                            ($model -eq 0x27) -or
                            ($model -eq 0x36) -or
                            ($model -eq 0x35)))
                    {

                        $kvaShadowRequired = $false
                    }
                }
            }
            else
            {
                throw ("Unsupported processor manufacturer: {0}" -f $cpu.Manufacturer)
            }

            [System.UInt32]$systemInformationClass = 196
            [System.UInt32]$systemInformationLength = 4

            $retval = $ntdll::NtQuerySystemInformation($systemInformationClass, $systemInformationPtr, $systemInformationLength, $returnLengthPtr)

            if ($retval -eq 0xc0000003)
            {
            }
            elseif ($retval -ne 0)
            {
                throw (("Querying kernel VA shadow information failed with error {0:X8}" -f $retval))
            }
            else
            {

                [System.UInt32]$kvaShadowEnabledFlag = 0x01
                [System.UInt32]$kvaShadowUserGlobalFlag = 0x02
                [System.UInt32]$kvaShadowPcidFlag = 0x04
                [System.UInt32]$kvaShadowInvpcidFlag = 0x08

                [System.UInt32]$flags = [System.UInt32][System.Runtime.InteropServices.Marshal]::ReadInt32($systemInformationPtr)

                $kvaShadowPresent = $true
                $kvaShadowEnabled = (($flags -band $kvaShadowEnabledFlag) -ne 0)
                $kvaShadowPcidEnabled = ((($flags -band $kvaShadowPcidFlag) -ne 0) -and (($flags -band $kvaShadowInvpcidFlag) -ne 0))

                if ($PSBoundParameters['Verbose'])
                {
                    # Write-Host "KvaShadowEnabled             :" (($flags -band $kvaShadowEnabledFlag) -ne 0)
                    # Write-Host "KvaShadowUserGlobal          :" (($flags -band $kvaShadowUserGlobalFlag) -ne 0)
                    # Write-Host "KvaShadowPcid                :" (($flags -band $kvaShadowPcidFlag) -ne 0)
                    # Write-Host "KvaShadowInvpcid             :" (($flags -band $kvaShadowInvpcidFlag) -ne 0)
                }
            }

            # Write-Host "Hardware requires kernel VA shadowing:"$kvaShadowRequired

            if ($kvaShadowRequired)
            {

                # Write-Host "Windows OS support for kernel VA shadow is present:"$kvaShadowPresent -ForegroundColor $(If ($kvaShadowPresent) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })
                # Write-Host "Windows OS support for kernel VA shadow is enabled:"$kvaShadowEnabled -ForegroundColor $(If ($kvaShadowEnabled) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })

                if ($kvaShadowEnabled)
                {
                    # Write-Host "Windows OS support for PCID optimization is enabled:"$kvaShadowPcidEnabled -ForegroundColor $(If ($kvaShadowPcidEnabled) { [System.ConsoleColor]::Green } Else { [System.ConsoleColor]::Red })
                }
            }


            $object | Add-Member -MemberType NoteProperty -Name KVAShadowRequired -Value $kvaShadowRequired
            $object | Add-Member -MemberType NoteProperty -Name KVAShadowWindowsSupportPresent -Value $kvaShadowPresent
            $object | Add-Member -MemberType NoteProperty -Name KVAShadowWindowsSupportEnabled -Value $kvaShadowEnabled
            $object | Add-Member -MemberType NoteProperty -Name KVAShadowPcidEnabled -Value $kvaShadowPcidEnabled
            $object | Add-Member -MemberType NoteProperty -Name kvaShadowEnabled -Value $kvaShadowEnabled

            return $object

        }
        finally
        {
            if ($systemInformationPtr -ne [System.IntPtr]::Zero)
            {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($systemInformationPtr)
            }

            if ($returnLengthPtr -ne [System.IntPtr]::Zero)
            {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($returnLengthPtr)
            }
        }
    }
}



Foreach ($C in $ComputerName)
{
    Describe "Speculative Execution Side-Channel Vulnerabilities Compliance for $C" {
        $Result = Invoke-Command -ComputerName $C -ScriptBlock ${function:Get-SpeculationControlSettings}
        Context "$C - CVE-2017-5715 [branch target injection]" {
            It 'Hardware support for branch target injection mitigation should be present' {
                $Result.BTIHardwarePresent | Should be $true
            }
            It 'Windows OS support for branch target injection mitigation should be present' {
                $Result.BTIWindowsSupportPresent | Should be $true
            }
            It 'Windows OS support for branch target injection mitigation should be enabled' {
                $Result.BTIWindowsSupportEnabled | Should be $true
            }
        }
        Context "$C - CVE-2017-5754 [rogue data cache load]" {
            if ($Result.KVAShadowRequired)
            {
                It 'Windows OS support for kernel VA shadow should be present' {
                    $Result.KVAShadowWindowsSupportPresent | Should be $true
                }
                It 'Windows OS support for kernel VA shadow should be enabled' {
                    $Result.KVAShadowWindowsSupportEnabled | Should be $true
                }
                if ($Result.kvaShadowEnabled)
                {
                    It 'Windows OS support for PCID optimization should be enabled' {
                        $Result.kvaShadowPcidEnabled | Should be $true
                    }
                }
            }
        }
    }
}