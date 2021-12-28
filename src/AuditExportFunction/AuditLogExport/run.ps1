# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function STARTED: $currentUTCtime"

# Prepare destination log storage account context
$logStorageConnectionString = $env:LogStorageConnectionString
$containerName = $env:LogContainerName
$storageCtx = New-AzStorageContext -ConnectionString $logStorageConnectionString

# Write an information log with the current time.
Write-Host "Storage Context Initialized"

# Hydrate credentials from environment variables
$username = $env:LogViewerUsername
$password = $env:LogViewerPassword
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $secPassword)

# Purge any existing connections / Establish a new connection
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
Get-PsSession | Remove-PSSession

# Upload the local CSV file to the blob container (-Force overwrites the file, if exists already)
Set-AzStorageBlobContent -Container $containerName -File $auditFilename -Blob $auditFilename -Context $storageCtx -Force

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"