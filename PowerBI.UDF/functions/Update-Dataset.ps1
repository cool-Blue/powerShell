function Update-Dataset {
    [CmdletBinding()]
    param (
        [string]$tenant,
        [string]$workspacename,
        [string]$datasetName,
        [string]$notificationOption = "",
        [switch]$NameOnly
    )

    $workspace = Get-PowerBIWorkspace -Name $workspacename
    $dataSet = Get-PowerBIDataset -WorkspaceId $workspace.Id | Where-Object Name -EQ $datasetName

    $workspaceId = $workspace.Id
    $datasetId = $dataSet.Id

    $dataSet | Select-Object -Property Name, Id | Out-String | Write-Verbose
    if (!$NameOnly) {
        # create rest URL to refresh dataset
        $datasetRefreshUrl = "groups/$workspaceId/datasets/$dataSetId/refreshes"
        # $datasetRefreshUrl = "/datasets/$dataSetId/refreshes"
        # build JSON for POST budy to refres dataset
        $postBody = @{notifyOption = $notificationOption} | ConvertTo-Json

        # invoke post operation, assuming the session is already connected to the service
        try {
            Invoke-PowerBIRestMethod -Url $datasetRefreshUrl -Method Post -Body $postBody -ContentType 'application/json' -Verbose
        } catch {
            Write-Error $PSItem.ToString()
            RefreshDataset -workspaceId $workspaceId -datasetId $datasetId -Verbose
        }
    }
}