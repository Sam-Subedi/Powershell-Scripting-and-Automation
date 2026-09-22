#Requires -Version 5.1
<#
.SYNOPSIS  Get all services and their logon accounts from remote computers.
.NOTES
    Uses CimInstance (modern replacement for WMI). Requires WinRM or DCOM.
    CSV Columns: ComputerName
    Usage   : .\15-Get-Services-on-Remote-Computers.ps1 -ComputerNames SRV01,SRV02
              .\15-Get-Services-on-Remote-Computers.ps1 -CsvPath servers.csv -FilterState Running
#>
param(
    [string[]]$ComputerNames,
    [string]$CsvPath,
    [string]$OutputPath  = ".\ServicesReport_$(Get-Date -Format 'yyyyMMdd').csv",
    [string]$FilterState = '',
    [string]$FilterName  = '',
    [switch]$UseCIM,
    [System.Management.Automation.PSCredential]$Credential
)
if ($CsvPath)          { $ComputerNames = (Import-Csv $CsvPath).ComputerName | Where-Object { $_ } }
if (-not $ComputerNames) { Write-Error 'Provide -ComputerNames or -CsvPath.'; exit 1 }

$report = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($computer in $ComputerNames) {
    $computer = $computer.Trim()
    Write-Host "Processing: $computer" -ForegroundColor Cyan
    if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Warning "  Unreachable."; $report.Add([PSCustomObject]@{ComputerName=$computer;ServiceName='N/A';Status='UNREACHABLE'}); continue
    }
    try {
        $svcs = if ($UseCIM) {
            $cP  = @{ComputerName=$computer}; if ($Credential) { $cP['Credential']=$Credential }
            $ses = New-CimSession @cP
            $r   = Get-CimInstance -CimSession $ses -ClassName Win32_Service; Remove-CimSession $ses; $r
        } else {
            $iP  = @{ComputerName=$computer;ScriptBlock={Get-CimInstance Win32_Service};ErrorAction='Stop'}
            if ($Credential) { $iP['Credential']=$Credential }
            Invoke-Command @iP
        }
        if ($FilterState) { $svcs = $svcs | Where-Object { $_.State -eq $FilterState } }
        if ($FilterName)  { $svcs = $svcs | Where-Object { $_.Name  -like $FilterName } }
        foreach ($s in $svcs) {
            $report.Add([PSCustomObject]@{ComputerName=$computer;ServiceName=$s.Name;DisplayName=$s.DisplayName;Status=$s.State;StartType=$s.StartMode;LogOnAs=$s.StartName;PathName=$s.PathName})
        }
        Write-Host "  $($svcs.Count) service(s) found." -ForegroundColor Green
    } catch { Write-Warning "  Error: $_"; $report.Add([PSCustomObject]@{ComputerName=$computer;ServiceName='ERROR';Status=$_.ToString()}) }
}
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($report.Count) entries to: $OutputPath" -ForegroundColor Green
$report | Group-Object ComputerName | Select-Object Count,Name | Format-Table -AutoSize
