
function Get-Dependent-Datasets {

    [CmdletBinding()]
    param (
        [string]$workspacename,
        [string]$dataflowName
    )
    
    $workspace = Get-PowerBIWorkspace -Name $workspacename
    $dataflow = GetDataflowIdFromName -workspaceId $workspace.Id -dataflowName $dataflowName

    $workspaceId = $workspace.Id
    $dataflowId = $dataflow.Id

    $dependentDatasets = GetDependentDatasets $workspaceId $dataflowId

    Write-Output $dependentDatasets
}