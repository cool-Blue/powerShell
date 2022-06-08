<#
    .DESCRIPTION
        Dot source all files in the functions sub-folder
#>

# Get path of function files
$functionPath = $PSScriptRoot + "\functions\"

# Get a list of the function file names
$functionList = Get-ChildItem -Path $functionPath -Name
# $functionList = Get-ChildItem | Where-Object {$_.Name -eq "Get-Credentials.ps1"} | Select-Object -Path $functionPath -Name

# Loop over all files and dot source them

foreach ($function in $functionList) {
    . ($functionPath + $function)
}