$user = Connect-PowerBIServiceAccount

$username = $user.UserName

Write-Host
write-host
Get-PowerBIWorkspace | Format-Table Name, Id
$bvorg = Get-PowerBIDataset 