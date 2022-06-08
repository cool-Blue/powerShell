# log into Azure AD user account with hard-coded user nane and encrypted password
$username = "myemail@mydomaine.com"
# Convert password to secure string
$securepassword = Get-Content $PSScriptRoot\scriptsencrypted_password1.txt | ConvertTo-SecureString
$securepassword
# Create PSCredential object to serve as login credentials
$credential = New-Object -TypeName System.Management.Automation.PSCredential `
                            -ArgumentList $username, $securepassword

# log in to Power Bi unattended without any user interraction

$user = Connect-PowerBIServiceAccount -Credential $credential
$username = $user.UserName

Write-Host
Write-Host "Now logged in as $username"

Get-PowerBIWorkspace | Format-Table Name, Id
# Get-PowerBIWorkspace

