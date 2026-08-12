Import-Module ActiveDirectory

$InputFile = "C:\path\to\file\search_users.txt"
$OutputFile = "C:\path\to\file\export_search_users.csv"
$count = 0

$Users = Get-Content $InputFile

$Results = foreach ($User in $Users) {
    
    # Removes hidden spaces and characters
    $User = $User.Trim()

    # Skip blank or dirty lines
    if ([string]::IsNullOrWhiteSpace($User)) {
        continue
    }

    # Escape of the apices
    $SearchName = $User.Replace("'","''")

    # Recover user from AD
    $ADUsers = Get-ADUser -Filter "Name -eq '$SearchName'" `
        -Properties UserPrincipalName, SamAccountName, Enabled, Description

    if ($null -eq $ADUsers) {

        Write-Warning "User not found in AD: $User"

        [PSCustomObject]@{
            InputName      = $User
            Name           = "#N/D"
            UPN            = "#N/D"
            SamAccountName = "#N/D"
            AccountStatus  = "Not found in AD"
            Description    = "#N/D"
        }

        $count++
        continue
    }

    if ($ADUsers.Count -gt 1) {
        Write-Warning "Multiple users found for: $User"
    }

    foreach ($ADUser in $ADUsers) {

        [PSCustomObject]@{
            InputName      = $User
            Name           = $ADUser.Name
            UPN            = $ADUser.UserPrincipalName
            SamAccountName = $ADUser.SamAccountName
            AccountStatus  = if ($ADUser.Enabled) { "Enabled" } else { "Disabled" }
            Description    = $ADUser.Description
        }
    }
}

Write-Host "Users not found in AD: $count"

# CSV export
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "CSV export generated in: $OutputFile"
