
$DomainName = "yourdomain.com"
$AdminGroupName = "Domain Admins"
$OUName = "OU=SecurityGroups,DC=yourdomain,DC=com"
$PasswordPolicySettings = @{
    "MinPasswordLength" = 12
    "PasswordHistoryCount" = 24
    "LockoutThreshold" = 3
    "LockoutDuration" = "00:30:00"
    "LockoutObservationWindow" = "00:30:00"
}
$GroupPolicyName = "SecurityConfigPolicy"

# Import the Active Directory module
Import-Module ActiveDirectory

# Function to create an AD security group
function Create-ADSecurityGroup {
    param (
        [string]$GroupName,
        [string]$GroupDescription
    )

    New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Description $GroupDescription -Path $OUName
}

# Function to set password policy
function Set-PasswordPolicy {
    param (
        [hashtable]$PolicySettings
    )

    Set-ADDefaultDomainPasswordPolicy -MinPasswordLength $PolicySettings["MinPasswordLength"] -PasswordHistoryCount $PolicySettings["PasswordHistoryCount"]
    Set-ADAccountLockoutPolicy -LockoutThreshold $PolicySettings["LockoutThreshold"] -LockoutDuration $PolicySettings["LockoutDuration"] -LockoutObservationWindow $PolicySettings["LockoutObservationWindow"]
}

# Function to create and link Group Policy
function Create-GroupPolicy {
    param (
        [string]$PolicyName
    )

    New-GPO -Name $PolicyName -Comment "Security Configuration Policy"
    $GPO = Get-GPO -Name $PolicyName
    New-GPLink -Name "Active Directory Security Configuration" -Target "ou=$OUName,$DomainName" -LinkEnabled Yes -GPO $GPO.Id
}

# Main script

# Create a security group for administrators
Create-ADSecurityGroup -GroupName $AdminGroupName -GroupDescription "Administrators Group"

# Add users to the administrators group (replace with actual usernames)
Add-ADGroupMember -Identity $AdminGroupName -Members "User1", "User2"

# Set the password policy
Set-PasswordPolicy -PolicySettings $PasswordPolicySettings

# Create and link Group Policy
Create-GroupPolicy -PolicyName $GroupPolicyName

# Configure Group Policy settings (add more as needed)
$GPOSettings = @{
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

ForEach ($Setting in $GPOSettings.GetEnumerator()) {
    Set-GPRegistryValue -Name $GroupPolicyName -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName $Setting.Key -Type String -Value $Setting.Value
}

# Configure Windows Firewall rules (add more as needed)
New-NetFirewallRule -DisplayName "Allow RDP Inbound" -Enabled True -Action Allow -Protocol TCP -Direction Inbound -Profile Domain -Program "%SystemRoot%\system32\svchost.exe" -Service RemoteDesktop -LocalPort 3389

# Refresh Group Policy
gpupdate /force

Write-Host "Active Directory security configuration complete."
