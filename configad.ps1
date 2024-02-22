
Import-Module ActiveDirectory

$domain = "yourdomain.com"
$adminGroupName = "Domain Admins"
$ouName = "OU=SecurityGroups,DC=yourdomain,DC=com"
$passwordPolicySettings = @{
    "MinPasswordLength" = 12
    "PasswordHistoryCount" = 24
    "LockoutThreshold" = 3
    "LockoutDuration" = "00:30:00"
    "LockoutObservationWindow" = "00:30:00"
}
$gpoName = "Security Policy"

# Create function to create Active Directory security group
function Create-ADSecurityGroup {
    param (
        [string]$groupName,
        [string]$groupDescription
    )

    try {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Description $groupDescription -Path $ouName
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Create function to set password policies
function Set-PasswordPolicy {
    param (
        [hashtable]$policySettings
    )

    try {
        Set-ADDefaultDomainPasswordPolicy -MinPasswordLength $policySettings["MinPasswordLength"] -PasswordHistoryCount $policySettings["PasswordHistoryCount"]
        Set-ADAccountLockoutPolicy -LockoutThreshold $policySettings["LockoutThreshold"] -LockoutDuration $policySettings["LockoutDuration"] -LockoutObservationWindow $policySettings["LockoutObservationWindow"]
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Create function to create GPO
function Create-GroupPolicy {
    param (
        [string]$gpoName
    )

    try {
        New-GPO -Name $gpoName -Comment "Security Configuration Policy"
        $gpo = Get-GPO -Name $gpoName
        New-GPLink -Name "Active Directory Security Configuration" -Target "ou=$ouName,$domain" -LinkEnabled Yes -GPO $gpo.Id
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Create "Domain Admins" security group
Create-ADSecurityGroup -GroupName $adminGroupName -GroupDescription "Administrators Group"

# Add members to the group
Add-ADGroupMember -Identity $adminGroupName -Members "User1", "User2"

# Set password policies
Set-PasswordPolicy -PolicySettings $passwordPolicySettings

# Create "Security Policy" GPO
Create-GroupPolicy -GpoName $gpoName

# Set GPO settings (add more as needed)
$gpoSettings = @{
    "Accounts: Rename administrator account" = "NewAdministratorName"
    "Accounts: Rename guest account" = "NewGuestName"
    "Accounts: Limit local account use of blank passwords to console logon only" = "Enabled"
    "Network security: Do not store LAN Manager hash value on next password change" = "Enabled"
    "Network security: Force logoff when logon hours expire" = "Enabled"
    "Interactive logon: Number of previous logons to cache" = 5
    "Interactive logon: Do not display last user name" = "Enabled"
    "Interactive logon: Machine account lockout threshold" = 10
    # Add more security configurations here
}

# Set registry settings via GPO
ForEach ($setting in $gpoSettings.GetEnumerator()) {
    try {
        Set-GPRegistryValue -Name $gpoName -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName $setting.Key -Type String -Value $setting.Value
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Create firewall rule to allow RDP
New-NetFirewallRule -DisplayName "Allow RDP Inbound" -Enabled True -Action Allow -Protocol TCP -Direction Inbound -Profile Domain -Program "%SystemRoot%\system32\svchost.exe" -Service RemoteDesktop -LocalPort 3389

# Force policy update
gpupdate /force

# Display completion message
Write-Host "Active Directory security configuration complete."
