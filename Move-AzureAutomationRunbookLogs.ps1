<#
.SYNOPSIS 
    Move logs for a given runbook into Azure BLOB Storage.

.DESCRIPTION
    Move logs for a given runbook into Azure BLOB Storage 
    See more information in associated blog post http://sqlblog.com/blogs/jamie_thomson/archive/2014/11/25/archiving-azure-automation-logs-to-azure-blob-storage.aspx


.EXAMPLE
    $Credential = Get-Credential -Message "Please supply username and password for Azure authentication"
    $StartTime = Get-Date -Year 2014 -Month 1 -Day 1
    $EndTime = Get-Date -Year 2015 -Month 1 -Day 1
    Move-RunbookLogsToAzureBlobStorage      -AutomationAccountName "myautomationaccount" `
                                            -StorageAccountName "mystorageaccount" `
                                            -StorageContainerName "mystoragecontainer" `
                                            -LogRootFolder "logs" `
                                            -SubscriptionName "mysubscription" `
                                            -Credential $Credential `
                                            -RunbookName "My-Runbook" `
                                            -StartTime $StartTime `
                                            -EndTime $EndTime

.PARAMETER AutomationAccountName
    Name of the Automation Account housing the runbook for which logs are to be moved

.PARAMETER StorageAccountName
    Name of the Storage Account into which to store the logs

.PARAMETER StorageContainerName
    Storage Account container into which to store the logs

.PARAMETER LogRootFolder
    Location within the Storage Account container into which to store the logs

.PARAMETER RunbookName
    Runbook for which to store logs

.PARAMETER SubscriptionName
    Azure subscription housing the Automation Account housing the runbook for which logs are to be moved

.PARAMETER Credential
    Credentials for authenticating to Azure. This needs to be an OrgId credential. See http://azure.microsoft.com/blog/2014/08/27/azure-automation-authenticating-to-azure-using-azure-active-directory/ for more details.

.PARAMETER StartTime
    Along with EndTime, define the time window for which logs should be moved

.PARAMETER EndTime
    Along with StartTime, define the time window for which logs should be moved

.NOTES
    AUTHOR: Jamie Thomson
#>

workflow Move-AzureAutomationRunbookLogs
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
   		[String]$AutomationAccountName,
		[Parameter(Mandatory=$True)]
   		[String]$StorageAccountName,
		[Parameter(Mandatory=$True)]
   		[String]$StorageContainerName,
        [Parameter(Mandatory=$True)]
   		[String]$LogRootFolder,
		[Parameter(Mandatory=$True)]
   		[String]$RunbookName,
        [Parameter(Mandatory=$True)]
   		[String]$SubscriptionName,
		[Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
        [DateTime]$StartTime,
		[Parameter(Mandatory=$false)]
        [DateTime]$EndTime
		
    )
    "Authenticating to Azure..." 
	$Null = Add-AzureAccount -Credential $Credential 
	$Null = Select-AzureSubscription -SubscriptionName $SubscriptionName 
	
    $localFolder = "c:\nlslocaldropfolder" 
    $mkdirResult = mkdir -Path $localFolder -Force # <-- file system on the VM upon which your script is running is accessible
    if ($StartTime -eq $null){$StartTime = Get-Date}
    if ($EndTime -eq $null){$EndTime = $StartTime}
    "StartTime = $StartTime, EndTime = $EndTime"
    $storageAccountKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName | %{ $_.Primary })
    InlineScript {
        $azureStorageContext = New-AzureStorageContext -StorageAccountName $using:StorageAccountName -StorageAccountKey $using:storageAccountKey 
        $notCurrentlyExecutingStatuses = "Completed","Stopped","Failed","Suspended"
        #At time of writing a book exists with Get-AzureAutomnationJob that mnifestd as an error whenever the StartTime & EndTime parameters are used
        Get-AzureAutomationJob -AutomationAccountName $using:AutomationAccountName -RunbookName $using:RunbookName -Verbose | 
            ? {$_.LastModifiedTime -ge $using:StartTime -and $_.LastModifiedTime -lt $using:EndTime} |
            ? {$notCurrentlyExecutingStatuses -contains $_.Status} | % {
                $blobProperties = @{"ContentType" = "text/plain"}
                $JobId = $_.Id
                "JobId = " + $JobId
                $blobName = ($_.StartTime).ToString("yyyyMMddHHmmss") + ".log"
                $jobLocalFile = "$using:localFolder\" + "job_$blobName"
                $_ | ConvertTo-Csv -NoTypeInformation -Delimiter "," | Select -Skip 1| Out-File -FilePath $jobLocalFile -Encoding ascii
                "Writing Azure Automation JobId=$jobId to https://$using:StorageAccountName.blob.core.windows.net/$using:StorageContainerName/$using:LogRootFolder/job/$using:RunbookName/$blobName" 
                Set-AzureStorageBlobContent -File $joblocalFile                                                                 `
									        -Container $using:StorageContainerName                                              `
									        -Properties $using:blobProperties                                                   `
									        -Context $azureStorageContext                                                       `
									        -Blob "$using:LogRootFolder/job/$using:RunbookName/$blobName"                       `
                                            -Force                                                                              `
    									    -Verbose                         

                $jobOutputLocalFile = "$using:localFolder\" + "joboutput_$blobName"
                Get-AzureAutomationJobOutput -AutomationAccountName $using:AutomationAccountName -Stream Any -Id $_.Id -Verbose | `
                    Select Type,Time,JobId,AccountId,RunbookVersionId,Text                                                      | `
                    ConvertTo-Csv -NoTypeInformation -Delimiter "~"                                                             | `
                    Select -Skip 1                                                                                              | `
                    Out-File -FilePath $jobOutputLocalFile -Encoding ascii
                    #Not using comma as the delimiter because there is always the possiblity of commas appearing in the log
                "Writing Azure Automation job log for JobId=$jobId to https://$usingStorageAccountName.blob.core.windows.net/$using:StorageContainerName/$using:LogRootFolder/joboutput/$using:RunbookName/$blobName" 
                Set-AzureStorageBlobContent -File $jobOutputlocalFile                                                              `
									        -Container $using:StorageContainerName                                              `
									        -Properties $using:blobProperties                                                   `
									        -Context $azureStorageContext                                                       `
									        -Blob "$using:LogRootFolder/joboutput/$using:RunbookName/$blobName"                 `
                                            -Force                                                                              `
    									    -Verbose    
        }
    }
}
