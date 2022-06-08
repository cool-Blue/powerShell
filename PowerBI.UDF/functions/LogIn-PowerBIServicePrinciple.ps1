function Connect-PowerBIWithServicePrinciple {
    [CmdletBinding()]
    param (
        [securestring]$sercretFilePath,
        [securestring]$sercretFileName,
        [string]$username,
        [string]$tenant
    )

    # #works - need to set proxy to allow authentication 
    # [System.Net.ServicePointManager]::SecurityProtocol = [system.Net.SecurityProtocolType]::Tls12
    # [system.net.webrequest]::defaultwebproxy = new-object system.net.webproxy('http://10.100.48.241:80')
    # [system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    # [system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true

    $path = $sercretFilePath | ConvertFrom-SecureString -AsPlainText
    $fileName = $sercretFileName | ConvertFrom-SecureString -AsPlainText

    # Convert password to secure string
    $encryptedPWFile = "$path\$fileName"
    $securepassword = Get-Content $encryptedPWFile | ConvertTo-SecureString
    $securepassword

    # Create PSCredential object to serve as login credentials
    $credential = New-Object -TypeName System.Management.Automation.PSCredential ( $username, $securepassword )

    # log in to Power Bi unattended without any user interraction

    $user = Connect-PowerBIServiceAccount -Tenant $tenant -ServicePrincipal -Credential $credential
    $username = $user.UserName

    Write-Host
    Write-Host "Now logged in as $username"

}