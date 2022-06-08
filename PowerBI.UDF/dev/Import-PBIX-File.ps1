# Connect-PowerBIServiceAccount | Out-Null
. .\Get-File-Path.ps1

$workspacename = "Bullivants Development"

$workspace = Get-PowerBIWorkspace -Name $workspacename

if($workspace) {
    $pbixFilePath = Get-File-Path
    $import = New-PowerBIReport -Path $pbixFilePath -Workspace -ConflictAction CreateOrOverwrite
    $import | Select *
}