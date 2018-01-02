#Below are all of the Powershell scripts necessary to create and run an Azure Data Factory pipeline to copy data from an AWS S3 account to an ADLS account, as explained in the referenced blog post. Before running these scripts complete the following:
### 1. Fill in all undefinied variables within the <>'s
### 2. Open a Powershell window and run Login-AzureRmAccount, viewing your subscriptions with Get-AzureRmSubscription, and choosing one with Select-AzureRmSubscription -SubscriptionId <your subscription id> 
### 3. Download the ADF defintion files under /ADF_Json_files/ in this Github
### 4. Generate the access keys for your AWS and ADLS account and add them into /ADF_Json_files/AmazonS3LinkedService.json and /ADF_Json_files/ADLSLinkedService.json - see blog for more detail

#Run each group of scripts individually to ensure child objects are created after their parent object. Copy and paste each group into your powershell window.

#Group 0: Define all parameters.
##Define personal variables for your Azure account
$ADFpath = "<path to location of the ADF JSON files>"
$resourceGroupName = "<your resource group>"
$dataFactoryName = "<your data factory>"

#Define all ADF object names
$integrationRuntimeName = "AWSToADLSIntegrationRuntime"
$ADLSLinkedServiceName = "ADLSLinkedService"
$AmazonS3LinkedServiceName = "AmazonS3LinkedService"
$ADLSDatasetName = "ADLSCopyDataset"
$AmazonS3DatasetName = "AmazonS3CopyDataset"
$AWSToADLSPipelineName = "AWSToADLSCopyPipeline"

##Define the relevant JSON definition file names for each object
$ADLSLinkedServiceFile = $ADLSLinkedServiceName + ".json"
$AmazonS3LinkedServiceFile = $AmazonS3LinkedServiceName + ".json"
$ADLSDatasetFile = $ADLSDatasetName + ".json"
$AmazonS3DatasetFile = $AmazonS3DatasetName + ".json"
$AWSToADLSPipelineFile = $AWSToADLSPipelineName + ".json"

#Group 1: Create the integration runtime and linked services
cd $ADFpath
#Integration runtime
Set-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $integrationRuntimeName -Location "East US 2"
#S3 Linked Service
Set-AzureRmDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AmazonS3LinkedServiceName -DefinitionFile $AmazonS3LinkedServiceFile
#ADLS Linked Service
Set-AzureRmDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $ADLSLinkedServiceName -DefinitionFile $ADLSLinkedServiceFile

#Group 2: Create the datasets
##S3 Dataset
Set-AzureRmDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AmazonS3DatasetName -DefinitionFile $AmazonS3DatasetFile
##ADLS Dataset
Set-AzureRmDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $ADLSDatasetName -DefinitionFile $ADLSDatasetFile

#Group 3: Create the pipeline
Set-AzureRmDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AWSToADLSPipelineName -DefinitionFile $AWSToADLSPipelineFile

#Group 4: Run the pipeline
##Run the pipeline
$runId = Invoke-AzureRmDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineName $AWSToADLSPipelineName

#Group 5: Monitor the pipeline until it returns a successful complete message
while ($True) {
    $Run = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineRunId $runId

    if ($Run) {
        if ($run.Status -ne 'InProgress') {
            Write-Output ("Pipeline run finished. The status is: " +  $Run.Status)
            $Run
            break
        }
        Write-Output  "Pipeline is running...status: InProgress"
    }

    Start-Sleep -Seconds 10
}

Write-Output "Activity run details:"
$Result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)
$Result

Write-Output "Activity 'Output' section:"
$Result.Output -join "`r`n"

Write-Output "Activity 'Error' section:"
$Result.Error -join "`r`n"
