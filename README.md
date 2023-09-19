
The script will create security groups, set password policies, configure Group Policy, and make other security-related changes to your Active Directory environment.


# Prerequisites

Before running the script, ensure you have:

    Windows Server 2019 or 2022

    Administrative privileges on the server

PowerShell Execution Policy set to allow script execution. You can do this by running:

    Set-ExecutionPolicy RemoteSigned


You can download the script directly from the GitHub repository:

    Go to the GitHub repository.
    Click on the "Code" button and select "Download ZIP."
    Extract the contents to a directory of your choice.

  # Running the Script

Open PowerShell as an administrator.

Navigate to the directory where you extracted the script And run it:

    .\ADsecurityconfig.ps1

The script will begin performing Active Directory security settings.



# Customizing the Script

Before running the script, It is important that you customize the script according to match your organization's specific requirements. 

Open the script using a text editor and modify the following variables:

    $DomainName: Set it to your Active Directory domain name.
    $AdminGroupName: Change the name of the administrators' group as needed.
    $OUName: Specify the organizational unit where you want to create security groups.
    $PasswordPolicySettings: Customize the password policy settings according to your organization's policies.
    $GroupPolicyName: Rename the Group Policy object to suit your preferences.

After running the script, When starting the script, it is important to check that the settings were applied as defined, you can use ***administrative tools like Group Policy Management Console and Active Directory Users*** to confirm the changes.

# Ps: Remember to test the script in an appropriate environment before running it directly in your production environment
