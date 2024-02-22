
# Overview

- Creating a "Domain Administrators" security group
    - Setting strong password policies
    - Creating a GPO "Security Policy"
      - Configuration of various security policies through GPO
      - Creating a firewall rule to allow RDP
     - Force policy update on all computers

# Prerequisites:

- Windows PowerShell 5.1 or higher
- Active Directory module installed
- Administrative permissions in Active Directory

# Instructions for use:

- Edit the script and configure the variables according to your environment:
  
            $domain: Domain name
  
            $adminGroupName: Name of the administrator group
  
            $ouName: Organizational unit where the group will be created
  
            $passwordPolicySettings: Password settings
  
            $gpoName: Name of the GPO

- Run the script in PowerShell with administrative privileges.

- Review the Active Directory event log to verify that the configuration was applied successfully.

- ***It is recommended to test the script in a test environment before deploying it to production.***
