#This file contains all of the Powershell scripts necessary to create and run the Azure Data Factory pipeline to copy data from an AWS S3 account to an ADLS account.
#Before running these scripts, ensure you are logged into your Azure account and subscription by running Login-AzureRmAccount and Select-AzureRmSubscription
#Also check that you have edited the corresponding JSON files (located in the GitHub under ADF_Json_files) with the necessary credentials and parameters to match your ADF account and resource group

#Define all object names here. Included are some default names to match the JSON files, edit them as necessary to match your own files.  
$resourceGroupName = "<your resource group>"
$dataFactoryName = "<your data factory>"
$integrationRuntimeName = "AWSToADLSIR"
$ADLSLinkedServiceName = "ADLSLinkedService"
$AmazonS3LinkedServiceName = "AmazonS3LinkedService"
$ADLSDatasetName = "ADLSCopyDataset"
$AmazonS3DatasetName = "AmazonS3CopyDataset"
$AWSToADLSPipelineName = "AWSToADLSCopyPipeline"

#Define the relevant JSON definition file names for each object
$ADLSLinkedServiceFile = $ADLSLinkedServiceName + ".json"
$AmazonS3LinkedServiceFile = $AmazonS3LinkedServiceName + ".json"
$ADLSDatasetFile = $ADLSDatasetName + ".json"
$AmazonS3DatasetFile = $AmazonS3DatasetName + ".json"
$AWSToADLSPipelineFile = $AWSToADLSPipelineName + ".json"

#Run each group of these scripts individually by copy+pasting into PowerShell window to ensure that each object is created before its dependents.

#Group 1: Create the integration runtime and linked services
Set-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName -$resourceGroupName -DataFactoryName $dataFactoryName -Name $integrationRuntimeName
Set-AzureRmDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AWSS3Linked -DefinitionFile $AmazonS3LinkedServiceFile
Set-AzureRmDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name "ADLSLinkedService" -DefinitionFile $ADLSLinkedServiceFile

#Group 2: Create the datasets
Set-AzureRmDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AmazonS3DatasetName -DefinitionFile $AmazonS3DatasetFile
Set-AzureRmDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $ADLSDatasetName -DefinitionFile $ADLSDatasetFile

#Group 3: Create the pipeline
Set-AzureRmDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $AWSToADLSPipelineName -DefinitionFile $AWSToADLSPipelineFile

#Group 4: Run and monitor the pipeline
#Run the pipeline
$runId = Invoke-AzureRmDataFactoryV2Pipeline -ResourceGroupName $resourceGroup -DataFactoryName $dataFactory -PipelineName $pipeline

#Monitor the pipeline until it finishes copying data
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