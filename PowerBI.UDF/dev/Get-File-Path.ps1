$DebugPreference = 'Continue'
function Find-File {
    [CmdletBinding()]
    param (
        [string]$fileNameFilter = "PBIX File(s)|*.pbix"
    )

    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $browse = New-Object System.Windows.Forms.OpenFileDialog
    $browse.initialDirectory = "C:\"
    $browse.Filter = "PBIX File(s)|*.pbix"
    $browse.Multiselect=$false
    $browse.Title = "Select a PBIX File"

    $loop = $true
    while($loop)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
            $loop = $false
		
		    # just terminate the loop
		
        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            Write-Debug $res
            if($res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    # return the seected path
    $browse.FileName
    $browse.Dispose()
}

Find-Folders