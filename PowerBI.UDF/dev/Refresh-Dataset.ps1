$workspacename = "..."
$datasetName = "..."
$notificationOption = "MailOnFailure"

$workspace = Get-PowerBIWorkspace -Name $workspacename
$dataSet = Get-PowerBIDataset -WorkspaceId $workspace.Id | Where-Object Name -EQ $datasetName

$workspaceId = $workspace.Id
$datasetId = $dataSet.Id

# create rest URL to refresh dataset
$datasetRefreshUrl = "groups/$workspaceId/datasets/$dataSetId/refreshes"
# build JSON for POST budy to refres dataset
$postBody = "{notifyOption: '$notificationOption'}"
# invoke post operation
Invoke-PowerBIRestMethod -Url:$datasetRefreshUrl -Method:Post -Body:$postBody -ContentType:'application/json'
