#Requires -Version 5.1
<#
.SYNOPSIS  List all Microsoft product updates installed — not just Windows patches like Get-HotFix.
.DESCRIPTION
    Uses the COM Microsoft.Update.Session API which reports ALL Microsoft product updates
    (Office, SQL Server, .NET, Windows, etc.). Supports remote computers via PSRemoting.
.NOTES
    Usage   : .\27-Get-All-Microsoft-Updates-Installed.ps1
              .\27-Get-All-Microsoft-Updates-Installed.ps1 -ComputerNames SRV01,SRV02
              .\27-Get-All-Microsoft-Updates-Installed.ps1 -FilterProduct Office -Since (Get-Date).AddDays(-90)
#>
param(
    [string[]]$ComputerNames = @($env:COMPUTERNAME),
    [string]$OutputPath      = ".\MicrosoftUpdates_$(Get-Date -Format 'yyyyMMdd').csv",
    [int]$MaxUpdates         = 1000,
    [string]$FilterProduct   = '',
    [datetime]$Since         = [datetime]::MinValue,
    [System.Management.Automation.PSCredential]$Credential
)
$getUpdates = {
    param($Max,$Filter,$Since,$Label)
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $count    = [Math]::Min($searcher.GetTotalHistoryCount(),$Max)
    $history  = $searcher.QueryHistory(0,$count)
    $codes    = @{1='In Progress';2='Succeeded';3='Succeeded With Errors';4='Failed';5='Aborted'}
    foreach ($u in $history) {
        if (-not $u.Title -or $u.ResultCode -eq 0) { continue }
        if ($Since -ne [datetime]::MinValue -and $u.Date -lt $Since) { continue }
        if ($Filter -and $u.Title -notlike "*$Filter*") { continue }
        [PSCustomObject]@{
            ComputerName = $Label
            Title        = $u.Title
            KB           = if ($u.Title -match 'KB(\d+)') { "KB$($Matches[1])" } else { '' }
            Date         = $u.Date
            Result       = if ($codes.ContainsKey($u.ResultCode)) { $codes[$u.ResultCode] } else { "Unknown($($u.ResultCode))" }
            Categories   = ($u.Categories | ForEach-Object { $_.Name }) -join '; '
        }
    }
}
$all = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($c in $ComputerNames) {
    $c = $c.Trim()
    Write-Host "Querying: $c" -ForegroundColor Cyan
    try {
        $r = if ($c -eq $env:COMPUTERNAME -or $c -eq 'localhost') {
            & $getUpdates $MaxUpdates $FilterProduct $Since $c
        } else {
            $iP = @{ComputerName=$c;ScriptBlock=$getUpdates;ArgumentList=$MaxUpdates,$FilterProduct,$Since,$c;ErrorAction='Stop'}
            if ($Credential) { $iP['Credential']=$Credential }
            Invoke-Command @iP
        }
        foreach ($u in $r) { $all.Add($u) }
        Write-Host "  $($r.Count) updates." -ForegroundColor Green
    } catch { Write-Warning "  Failed: $_" }
}
$sorted = $all | Sort-Object Date -Descending
$sorted | Select-Object ComputerName,Date,KB,Result,Title | Format-Table -AutoSize -Wrap
$sorted | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($sorted.Count) updates to: $OutputPath" -ForegroundColor Green
$sorted | Group-Object Result | Select-Object Count,Name | Sort-Object Count -Descending | Format-Table -AutoSize
