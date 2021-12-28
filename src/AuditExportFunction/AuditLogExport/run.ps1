# Input bindings are passed in via param block.
param($Timer)

# Enable the AzureRM Aliasing
Enable-AzureRmAlias

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# Hydrate credentials from environment variables
$username = $env:LogViewerUsername
$password = $env:LogViewerPassword
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $secPassword)

# Close any existing connection, Establish a new connection
Import-Module ExchangeOnlineManagement
Get-PsSession | Remove-PSSession
Connect-ExchangeOnline -Credential $credential

# Get the logs of previous day
$startDate = (Get-Date).Date.AddDays(-1)
$endDate = (Get-Date).Date
$auditlogs = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -RecordType PowerBIAudit

# Export the results to a local CSV file
$auditFilename = "AuditLogs-" + $startDate.ToString("yyyyMMdd") + ".csv"
$auditlogs | Select-Object -Property CreationDate,UserIds,RecordType,AuditData | Export-Csv $auditFilename

# Prepare log storage destination
$logStorageConnectionString = $env:LogStorageConnectionString
$containerName = $env:LogContainerName

$storageCtx = New-AzureStorageContext -ConnectionString $logStorageConnectionString

# Upload the local CSV file to the blob container
Set-AzureStorageBlobContent -Container $containerName -File $auditFilename -Blob $auditFilename -Context $storageCtx

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Disconnect from Exchange online session
Disconnect-ExchangeOnline -Confirm:$false

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
