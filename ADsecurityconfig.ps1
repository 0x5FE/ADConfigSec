
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

if (Get-Module -Name "ActiveDirectory" -ListAvailable) {
    Import-Module ActiveDirectory
} else {
    Write-Host "The Active Directory module is not available. Make sure you have installed the RSAT tools."
    Exit
}

function Create-ADSecurityGroup {
    param (
        [string]$GroupName,
        [string]$GroupDescription
    )

    New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Description $GroupDescription -Path $OUName
}

function Set-PasswordPolicy {
    param (
        [hashtable]$PolicySettings
    )

    Set-ADDefaultDomainPasswordPolicy -MinPasswordLength $PolicySettings["MinPasswordLength"] -PasswordHistoryCount $PolicySettings["PasswordHistoryCount"]
    Set-ADAccountLockoutPolicy -LockoutThreshold $PolicySettings["LockoutThreshold"] -LockoutDuration $PolicySettings["LockoutDuration"] -LockoutObservationWindow $PolicySettings["LockoutObservationWindow"]
}

function Create-GroupPolicy {
    param (
        [string]$PolicyName
    )

    New-GPO -Name $PolicyName -Comment "Security Configuration Policy"
    $GPO = Get-GPO -Name $PolicyName
    New-GPLink -Name "Active Directory Security Configuration" -Target "ou=$OUName,$DomainName" -LinkEnabled Yes -GPO $GPO.Id
}


Create-ADSecurityGroup -GroupName $AdminGroupName -GroupDescription "Administrators Group"

Add-ADGroupMember -Identity $AdminGroupName -Members "User1", "User2"

Set-PasswordPolicy -PolicySettings $PasswordPolicySettings

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

New-NetFirewallRule -DisplayName "Allow RDP Inbound" -Enabled True -Action Allow -Protocol TCP -Direction Inbound -Profile Domain -Program "%SystemRoot%\system32\svchost.exe" -Service RemoteDesktop -LocalPort 3389

gpupdate /force

Write-Host "Active Directory security configuration complete."
