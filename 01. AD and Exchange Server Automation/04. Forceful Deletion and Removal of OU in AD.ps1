Import-Module ActiveDirectory

# Path of the main Employee OU
$employeeOU = "OU=Employee,DC=abc,DC=com"

# Check if Employee OU exists
if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$employeeOU'" -ErrorAction SilentlyContinue) {

    Write-Host "Starting cleanup of Employee OU..." -ForegroundColor Cyan

    # Remove all users inside Employee OU and sub-OUs
    $users = Get-ADUser -SearchBase $employeeOU -Filter *
    foreach ($user in $users) {
        try {
            Remove-ADUser $user -Confirm:$false
            Write-Host "Deleted user: $($user.SamAccountName)" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to delete user $($user.SamAccountName): $_"
        }
    }

    # Remove all groups inside Employee OU and sub-OUs
    $groups = Get-ADGroup -SearchBase $employeeOU -Filter *
    foreach ($group in $groups) {
        try {
            Remove-ADGroup $group -Confirm:$false
            Write-Host "Deleted group: $($group.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to delete group $($group.Name): $_"
        }
    }

    # Remove all sub-OUs under Employee OU
    $subOUs = Get-ADOrganizationalUnit -SearchBase $employeeOU -Filter *
    foreach ($ou in $subOUs) {
        try {
            # Uncheck Protect object from accidental deletion if needed
            Set-ADOrganizationalUnit $ou -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue

            Remove-ADOrganizationalUnit $ou -Recursive -Confirm:$false
            Write-Host "Deleted OU: $($ou.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to delete OU $($ou.Name): $_"
        }
    }

    # Finally remove Employee OU itself
    try {
        Set-ADOrganizationalUnit $employeeOU -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
        Remove-ADOrganizationalUnit $employeeOU -Recursive -Confirm:$false
        Write-Host "Employee OU deleted successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to delete Employee OU: $_"
    }

} else {
    Write-Host "Employee OU does not exist. Nothing to delete." -ForegroundColor Yellow
}