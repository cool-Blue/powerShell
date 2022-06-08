# get password as secure string
function Get-Credentials {
    [CmdletBinding()]
    param (
        [securestring]$secureFilePath,
        [securestring]$secureFileName
    )
    $credFilePath = $secureFilePath | ConvertFrom-SecureString -AsPlainText
    $credFileName = $secureFileName | ConvertFrom-SecureString -AsPlainText
    # "$credFilePath\$credFileName"
    $credential = Get-Credential
    $credential.Password | ConvertFrom-SecureString | Set-Content "$credFilePath\$credFileName"
}