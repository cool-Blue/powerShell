#region Log Utilities
# ==================================================================
# Verbose flag
# ==================================================================
[Boolean]$glovalVerbose=$false
[String]$globalLogFile=$null

# ==================================================================
# Function to set global log file
# ==================================================================
function SetLogFile([String]$logFile)
{
	$global:globalLogFile = $logFile
}

# ==================================================================
# Function to set verbose flag
# ==================================================================
function SetVerbose([Boolean]$v)
{
	$global:glovalVerbose = $v
}

# ==================================================================
# Console logging method
# ==================================================================
function SafeLog
{
	[CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$message,
		[Parameter(Mandatory=$false)][String]$color
	)
	try
	{
		$ErrorActionPreference="SilentlyContinue"
		if ($color -eq $null) 
		{
			$color = "Green"
		}
	   	$messageInternal = "$(get-date -format `"hh:mm:ss`"):" + $message
		write-host $messageInternal -foregroundcolor $color
		
		if ($global:globalLogFile -ne $null)
		{
			$messageInternal | out-file -Filepath $global:globalLogFile -encoding ascii -append
		}
		$ErrorActionPreference = "Continue"
	}
	catch
	{
	}
}

# ==================================================================
# Log and throw error
# ==================================================================
function DFThrowError($message)
{
	SafeLog -message $message -color "Red"
	throw $message
}

# ==================================================================
# Log error
# ==================================================================
function DFLogError($message)
{
    SafeLog -message $message -color "Red"
}

# ==================================================================
# Log verbose
# ==================================================================
function DFLogVerbose($message)
{
	if ($global:glovalVerbose)
	{
		SafeLog -message $message -color "Gray"
	}
}

# ==================================================================
# Log message
# ==================================================================
function DFLogMessage($message)
{
    SafeLog -message $message -color "Blue"
}

# ==================================================================
# Log message
# ==================================================================
function DFLogHighlight($message)
{
    SafeLog -message $message -color "Green"
}

# ==================================================================
# Log warning
# ==================================================================
function DFLogWarning($message)
{
    SafeLog -message $message -color "Yellow"
}
#endregion

#region Power BI Service Utilities

# ==================================================================
# Logs into a Power BI environment
# ==================================================================
function LoginPowerBi([String]$Environment)
{
	DFLogMessage("Logging in to PowerBI")
	if ($Environment -ne "" -and $Environment -ne $null)
    {
        Connect-PowerBIServiceAccount -Environment $Environment
    }
    else 
    {
        Login-PowerBI
    }
}

# ==================================================================
# Verifies and gets a workspace id from Power BI
# ==================================================================
function GetWorkspaceIdFromName([String]$workspaceName)
{
	DFLogMessage("Getting workspace info : $workspaceName")
	$myRestResult = Invoke-PowerBIRestMethod -Url 'Groups' -Method Get | ConvertFrom-Json

    DFLogVerbose("Looking for workspace $workspaceName")
	foreach ($item in $myRestResult.value) 
	{
		if ($item.name -eq $workspaceName) 
		{
			$id = $item.id
            DFLogMessage("Workspace Name:$workspaceName Id:$id")
			return $id
        }
	}
	
	DFThrowError("Workspace [$workspaceName] not found.")	
}

# ==================================================================
# Gets a list of dataflows in a workspace
# ==================================================================
function GetDataflowsForWorkspace([String]$workspaceId)
{
	DFLogMessage("Getting list of dataflows from workspace Id:$workspaceId")
	$myRestResult = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/dataflows" -Method Get | ConvertFrom-Json
	[Hashtable]$dataflows = @{}

	foreach ($item in $myRestResult.value) 
	{
		$id =$item.objectId
		$name =$item.name
		DFLogVerbose("Dataflow Id:$id Name:$name")
		$dataflows[$id] = $item
	}

	DFLogMessage("Fetched dataflows. Count: " + $dataflows.Count)
    return $dataflows;
}

# ==================================================================
# Gets the dataflow id for a given dataflow name in a workspace
# ==================================================================
function GetDataflowIdFromName([String]$workspaceId, [String]$dataflowName)
{
	DFLogMessage("Getting list of dataflows from workspace Id:$workspaceId")
	$myRestResult = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/dataflows" -Method Get | ConvertFrom-Json
	
	foreach ($item in $myRestResult.value) 
	{
		if ($item.name -eq $dataflowName) 
		{
			$id = $item.objectId
			DFLogMessage("Dataflow Name:$dataflowName Id:$id")
			return $id
		}
	}

	DFThrowError("Workspace [$dataflowName] not found.")	
}

# ==================================================================
# Gets the list of dataset ids referred to by a dataflow
# ==================================================================
function GetDependentDatasets([String]$workspaceId, [String]$dataflowId)
{
	$dependentDatasets = @()
	DFLogMessage("Getting dataset to dataflow link in workspace Id:$workspaceId")
	$datasetToDataflowLink = Invoke-PowerBIRestMethod -Url /groups/$workspaceId/datasets/upstreamDataflows -Method Get | ConvertFrom-Json
	foreach ($item in $datasetToDataflowLink.value) 
	{
		if ($item.dataflowObjectId -eq $dataflowId) 
		{
			$dependentDatasets += $item
		}
	}

	DFLogMessage("Dependent dataset count:" + $dependentDatasets.count)
	return $dependentDatasets
}

# ==================================================================
# Gets the content of a dataflow
# ==================================================================
function GetDataflow([String]$workspaceId, [String]$dataflowId, [String]$dataflowName)
{
	DFLogMessage("Downloading dataflow Id:$dataflowId Name:$dataflowName")
	$modelJson = Invoke-PowerBIRestMethod -Url /groups/$workspaceId/dataflows/$dataflowId -Method Get | ConvertFrom-Json
	return $modelJson
}

# ==================================================================
# Gets the list of reference models by parsing a model.json file
# ==================================================================
function GetReferenceModels($modelJson)
{
	$referenceModels= @()
	foreach ($item in $modelJson.referenceModels) 
	{
		$parts = $item.id -split "/"
		$s = '{"WorkspaceId":"' + $parts[0] + '","DataflowId":"' + $parts[1] + '", "Location":"' + $item.location + '"}'
		$referenceModel =  $s | ConvertFrom-Json
		DFLogVerbose("Reference model: $referenceModel")
		$referenceModels += $referenceModel
	}

	return $referenceModels
}

# ==================================================================
# Removes partitions from a model.json
# ==================================================================
function PrepareForImport($modelJson)
{
	DFLogVerbose("Removing partitions from model")
	for ($i=0; $i -lt $modelJson.entities.Count; $i++)
	{
		if(Get-Member -inputobject $modelJson.entities[$i] -name "partitions" -Membertype Properties)
		{
            $modelJson.entities[$i].PSObject.properties.remove('partitions')
		}
	}
}

# ==================================================================
# Fixes the reference links in a model.json
# ==================================================================
function FixReference($modelJson, $lookupModelId, $workspaceId, $modelId)
{
	$newReference = "$workspaceId/$modelId"
	DFLogVerbose("Looking for references: $lookupModelId to $newReference")
	for ($i=0; $i -lt $modelJson.referenceModels.Count; $i++)
	{
		DFLogVerbose("Reference model: " + $modelJson.referenceModels[$i].Id)
		if ($modelJson.referenceModels[$i].Id.contains($lookupModelId))
		{
			$oldReference = $modelJson.referenceModels[$i].Id
			DFLogVerbose("Found references: $oldReference")
			$modelJson.referenceModels[$i].Id = $newReference
			$modelJson.referenceModels[$i].Location = $null

			for ($j=0; $j -lt $modelJson.entities.Count; $j++)
			{
				if ($modelJson.entities[$j].modelId -eq $oldReference)
				{
					$modelJson.entities[$j].modelId = $newReference
				}
			}
		}
	}
}

# ==================================================================
# Refreshes a dataset
# ==================================================================
function RefreshDataset([String]$workspaceId, [String]$datasetId)
{
	DFLogMessage("Trigerring a refresh for dataset:$datasetId")
	$body = @{
		notifyOption          = "MailOnFailure"
	} | ConvertTo-Json
	Invoke-PowerBIRestMethod -Url /datasets/$datasetId/refreshes -Method Post -Body $body | ConvertFrom-Json
	DFLogMessage("Triggered the refresh successsfully")
}

# ==================================================================
# Refreshes a dataflow and waits for the refresh to complete
# ==================================================================
function RefreshModel([String]$workspaceId, [String]$dataflowId)
{
	$lastTransaction = GetLastTransactionForDataflow $workspaceId $dataflowId
	$lastTransactionId = $null
	if ($null -ne $lastTransaction)
	{
		$lastTransactionId = $lastTransaction.id
		DFLogMessage("Last transaction id:$lastTransactionId")
	}

	DFLogMessage("Trigerring a refresh for dataflow:$dataflowId")
	$body = @{
		notifyOption          = "MailOnFailure"
	} | ConvertTo-Json
	Invoke-PowerBIRestMethod -Url /groups/$workspaceId/dataflows/$dataflowId/refreshes -Method Post -Body $body | ConvertFrom-Json

	DFLogMessage("Waiting for new transaction to start")
	Start-Sleep -Seconds 2.0
	$newTansaction = $null
	$sleepDurationInSeconds = 5
	$maxTimeForPrepareSeconds = 5 * 60
	$maxIters = $maxTimeForPrepareSeconds / $sleepDurationInSeconds
	For ($i=0; $i -le $maxIters; $i++)
	{
		$currentTransaction = GetLastTransactionForDataflow $workspaceId $dataflowId
		if ($null -ne $currentTransaction -and $lastTransactionId -ne $currentTransaction.id)
		{
			$newTansaction = $currentTransaction
			break;
		}

		Start-Sleep -Seconds $sleepDurationInSeconds
	}

	if ($null -eq $newTansaction)
	{
		DFThrowError("Refresh failed. Request timed out")
	}
	
	$txnid = $newTansaction.id
	DFLogMessage("New transaction id:$txnid")

	# Wait for transaction to be completed
	$startDate = Get-Date
	$refreshState = 'inProgress'
	$headers = @{Accept = "application/json, text/plain, */*"}
	$sleepDurationInSeconds = 10
	while($refreshState -eq 'inProgress')
	{
		$refreshStatus = Invoke-PowerBIRestMethod -Url /groups/$workspaceId/dataflows/transactions/$txnid -Method Get -Headers $headers | ConvertFrom-Json
		$refreshState = $refreshStatus.state
		$currentDate = Get-Date
		$ts = New-TimeSpan -Start $startDate -End $currentDate

		if ($refreshState -eq 'failure')
		{
			DFThrowError("Refresh failed after " + $ts.TotalSeconds + " seconds. Message=" + $refreshStatus.exceptionData.message)
		}

		if ($refreshState -eq 'success')
		{
			DFLogMessage("Refresh completed in " + $ts.TotalSeconds + " seconds")
			break
		}

		DFLogMessage("`tRefresh in progress after " + $ts.TotalSeconds + " seconds. Waiting for $sleepDurationInSeconds seconds before polling..")
		Start-Sleep -Seconds $sleepDurationInSeconds
	}
}

function GetLastTransactionForDataflow([String]$workspaceId, [String]$dataflowId)
{
	DFLogVerbose("Getting top 1 transaction for dataflow:$dataflowId")
	$transactions = Invoke-PowerBIRestMethod -Url /groups/$workspaceId/dataflows/$dataflowId/transactions?top=1 -Method Get | ConvertFrom-Json
	if ($null -eq $transactions -or $null -eq $transactions.value -or $transactions.value.length -eq 0)
	{
		return $null
	}

	return $transactions.value[0]
}

# ==================================================================
# Imports a model.json and returns its id once imported
# ==================================================================
function ImportModel($workspaceId, $modelId, $modelJson, $dataflows)
{
	PrepareForImport($modelJson)

	# Generate the payload
	$string_json = $modelJson | ConvertTo-Json -depth 100
    $boundary = [System.Guid]::NewGuid().ToString(); 
    $LF = "`r`n";
    $bodyLines = ( 
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$FieldName`"",
        "Content-Type: application/json$LF",
        $string_json,
        "--$boundary--$LF" 
	) -join $LF
	
	# Call method to start import
	$importUri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/imports?datasetDisplayName=model.json";
	$overwriteMode = $false
	if ($null -ne $modelId)
	{
		$importUri += "&nameConflict=Overwrite"
		$overwriteMode = $true
	}
	else 
	{
		$importUri += "&nameConflict=GenerateUniqueName"
	}

	$startDate = (Get-Date).ToUniversalTime()
	$token = Get-PowerBIAccessToken -AsString
	$headers = @{Authorization = "$token"}
    $response = $null
	try 
	{
		$response = Invoke-RestMethod -Uri $importUri -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyLines))
		DFLogMessage("Started model import Id: " + $response.id + " at UTC: $startDate")
	}
	catch 
	{
		$x = $_ | ConvertFrom-Json
		$code = $x.error.code
		$message = $x.error.message
		DFThrowError("Import failed. Code=$code, Message=$message")
	}

	# Wait for import to be completed
	Start-Sleep -Seconds 1.0
    $importId = $response.id
	$importState = 'Publishing'
	$lastUpdated = $startDate
	$importStatus = $null
	$counter = 0
	$maxIterations = 3 * 60
	while($importState -eq 'Publishing' -or $lastUpdated -le $startDate)
	{
		try
		{
			$importStatus = Invoke-PowerBIRestMethod -Url /groups/$workspaceId/imports/$importId -Method Get | ConvertFrom-Json
			$importState = $importStatus.importState
			$lastUpdated = ([datetime]::Parse($importStatus.updatedDateTime)).ToUniversalTime() 
			DFLogVerbose("Started=$startDate importState=$importState LastUpdated=$lastUpdated")
			Start-Sleep -Seconds 1.0
			$counter += 1

			if ($overwriteMode -and $counter -ge $maxIterations)
			{
				break
			}
		} 
		catch 
		{
            $x = $_ | ConvertFrom-Json
			$code = $x.error.code
			$message = $x.error.message
			DFThrowError("Import failed. Code=$code, Message=$message")
        }
	}
	
	# Check for errors
	if ($importState.equals('Failed'))
	{
        $code = $importStatus.error.code
        $details = $importStatus.error.details
        DFThrowError("Import Failed with code [$code] and details [$details]")
	}
	if ($overwriteMode -and $counter -ge $maxIterations)
	{
		DFThrowError("Import failed. Request timed out")
	}
	
	# Obtain the new model id
	if ($null -ne $modelId)
	{
		return $dataflows[$modelId]
	}
	else 
	{
		$newDataflows = GetDataflowsForWorkspace($workspaceId)

		foreach ($dataflowid in $newDataflows.Keys) 
		{
			if ($null -eq $dataflows[$dataflowid])
			{
				DFLogVerbose("Found imported dataflow=$dataflowid")
				return $newDataflows[$dataflowid]
			}
		}
	}

	DFThrowError("Unexpected error. Cannot find imported model in the workspace")
}

# ==================================================================
# Reads a model.json from a file
# ==================================================================
function ReadModelJson([String]$fileName)
{
	If(!(test-path $fileName))
    {
        DFThrowError("File $fileName does not exist")
    }
	$json = Get-Content -Encoding UTF8 -Raw -Path $fileName | ConvertFrom-Json
	return $json
}

# ==================================================================
# Finds a model id to overwrite
# ==================================================================
function GetOverrwiteModelId($dataflows, $overwrite, $modelName)
{
	$overwriteModelId = $null
	if ($overwrite)
	{
		foreach ($dataflow in $dataflows.Values) 
		{
			if ($modelName -eq $dataflow.name)
			{
				$overwriteModelId = $dataflow.objectId
			}
		}
	}

	DFLogVerbose("Overwrite for model $modelName : $overwriteModelId")
	return $overwriteModelId
}


#endregion

#region File Utilities

# ==================================================================
# Verifies if a folder exists
# ==================================================================
function VerifyDirectory([String]$directoryName)
{
	If(!(test-path $directoryName))
    {
        DFThrowError("Directory $directoryName does not exist")
    }
}

# ==================================================================
# Creates a folder if it does not exist
# ==================================================================
function CreateDirectoryIfNotExists([String]$directoryName)
{
	If(!(test-path $directoryName))
    {
        DFLogMessage("Creating folder $directoryName")
        New-Item -ItemType Directory -Force -Path $directoryName
    }
}

# ==================================================================
# Recreate a folder
# ==================================================================
function RecreateDirectory([String]$directoryName)
{
	If((test-path $directoryName))
    {
        DFLogVerbose("Deleting folder $directoryName")
        Remove-Item -Path $directoryName
	}
	
	DFLogMessage("Creating folder $directoryName")
    New-Item -ItemType Directory -Force -Path $directoryName
}

# ==================================================================
# Deletes a file if it exists
# ==================================================================
function DeleteFileIfExists([String]$fileName)
{
	If((test-path $fileName))
    {
        DFLogVerbose("Deleting file $fileName")
        Remove-Item -Path $fileName
    }
}