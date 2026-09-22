#Requires -Version 5.1
<#
.SYNOPSIS  Execute PowerShell commands on remote computers via PSRemoting, CIM, or Scheduled Task.
.NOTES
    Methods : PSRemoting (recommended), CIM (DCOM/WMI), ScheduledTask (background silent)
    PSRemoting requires WinRM enabled on targets: Enable-PSRemoting -Force
    Usage   : .\24-Run-Commands-Remotely-on-Domain-Computers.ps1 -ComputerNames SRV01,SRV02 -ScriptBlock 'Get-Service | Where-Object Status -eq Running'
              .\24-Run-Commands-Remotely-on-Domain-Computers.ps1 -ComputerNames SRV01 -ScriptBlock 'hostname' -Method CIM
#>
param(
    [Parameter(Mandatory)][string[]]$ComputerNames,
    [Parameter(Mandatory)][string]$ScriptBlock,
    [ValidateSet('PSRemoting','CIM','ScheduledTask')][string]$Method = 'PSRemoting',
    [System.Management.Automation.PSCredential]$Credential,
    [string]$OutputPath = ''
)
$sb = [scriptblock]::Create($ScriptBlock)

$results = switch ($Method) {
    'PSRemoting' {
        Write-Host "PSRemoting -> $($ComputerNames -join ', ')" -ForegroundColor Cyan
        $p = @{ComputerName=$ComputerNames;ScriptBlock=$sb;ErrorAction='Continue'}
        if ($Credential) { $p['Credential']=$Credential }
        Invoke-Command @p
    }
    'CIM' {
        $ComputerNames | ForEach-Object {
            Write-Host "CIM -> $_" -ForegroundColor Cyan
            try {
                $cP  = @{ComputerName=$_}; if ($Credential) { $cP['Credential']=$Credential }
                $ses = New-CimSession @cP
                $r   = Invoke-CimMethod -CimSession $ses -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine="powershell.exe -NonInteractive -Command `"$ScriptBlock`""}
                Remove-CimSession $ses
                [PSCustomObject]@{ComputerName=$_;ProcessID=$r.ProcessId;ReturnValue=$r.ReturnValue;Status=if($r.ReturnValue -eq 0){'Success'}else{"Failed($($r.ReturnValue)))"}}
            } catch { [PSCustomObject]@{ComputerName=$_;Status="Error: $_"} }
        }
    }
    'ScheduledTask' {
        $ComputerNames | ForEach-Object {
            $tn = "PSExec_$(Get-Random)"
            Write-Host "ScheduledTask -> $_" -ForegroundColor Cyan
            try {
                $iP = @{ComputerName=$_;ErrorAction='Stop'}; if ($Credential) { $iP['Credential']=$Credential }
                Invoke-Command @iP -ScriptBlock {
                    param($n,$cmd)
                    $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NonInteractive -Command `"$cmd`""
                    $t = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(3)
                    Register-ScheduledTask -TaskName $n -Action $a -Trigger $t -RunLevel Highest -Force | Out-Null
                    Start-ScheduledTask -TaskName $n; Start-Sleep 10
                    Unregister-ScheduledTask -TaskName $n -Confirm:$false
                } -ArgumentList $tn,$ScriptBlock
                [PSCustomObject]@{ComputerName=$_;Status='Task executed'}
            } catch { [PSCustomObject]@{ComputerName=$_;Status="Error: $_"} }
        }
    }
}
Write-Host '=== Results ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
if ($OutputPath) { $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved: $OutputPath" -ForegroundColor Green }
