Archive Azure Automation logs to Azure BLOB Storage
===================================================

            

 

 

This runbook will archive logs for a given runbook and for whose jobs started in a given time period to a given Azure BLOB Storage account. The Azure storage account and location therein is specified via the $SubscrptionName, $StorageAccountName, $StorageContainerName,
 $LogRootFolder parameters. The runbook whose logs are to be archived is specified via the $AutomationAccountName & $RunbookName parameters. The time period whose jobs should be archived is specified via $StartTime & $EndTime parameters.


The code snippet above can be used to run this runbook, it demonstrates the required parameters.


See more information in associated blog post [http://sqlblog.com/blogs/jamie_thomson/archive/2014/11/25/archiving-azure-automation-logs-to-azure-blob-storage.aspx](http://sqlblog.com/blogs/jamie_thomson/archive/2014/11/25/archiving-azure-automation-logs-to-azure-blob-storage.aspx)


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
