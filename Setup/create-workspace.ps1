az login
az account set -s "Microsoft Azure Enterprise"
az account show

# az extension remove -n azure-cli-ml
# az extension remove -n ml
# az extension add -n ml --debug

$workspaceCount = 35
$yamlTemplate = Get-Content -Path "./workspace.yaml"
$location = "westus2"
$subscriptionId = az account show --query id --output tsv
$tenantId = az account show --query tenantId -o tsv

# Create AML workspaces

(1..$workspaceCount) | ForEach-Object {
    $workspaceName = "azureailab{0:D2}" -f $_
    $resourceGroupName = $workspaceName
    
    Write-Output "Creating workspace $($workspaceName)..."

    az group create --name $resourceGroupName --location $location
    az storage account create --name $workspaceName --resource-group $resourceGroupName --location $location --sku Standard_LRS
    az keyvault create --name $workspaceName --resource-group $resourceGroupName --location $location
    az monitor app-insights component create --app $workspaceName --resource-group $resourceGroupName --location $location
    
    $yamlContent = $yamlTemplate.Replace("<NAME>", $workspaceName).Replace("<SUBSCRIPTION_ID>", $subscriptionId).Replace("<RESOURCE_GROUP>", $resourceGroupName)
    Set-Content -Path "$($workspaceName).yaml" -Value $yamlContent

    az ml workspace create --resource-group $resourceGroupName --file "$($workspaceName).yaml"

    Remove-Item -Path "$($workspaceName).yaml"
}

# Set Contributor role assignments to users

(1..$workspaceCount) | ForEach-Object {
    $workspaceName = "azureailab{0:D2}" -f $_
    $resourceGroupName = $workspaceName
    $userName = "azureai-lab-{0:D2}@solliance.net" -f $_

    az role assignment create --assignee $userName --role "Contributor" --resource-group $resourceGroupName
}

# Create compute instances

$ciYamlTemplate = Get-Content -Path "./compute-instance.yaml"

(1..$workspaceCount) | ForEach-Object {
    $workspaceName = "azureailab{0:D2}" -f $_
    $resourceGroupName = $workspaceName
    $userName = "azureai-lab-{0:D2}@solliance.net" -f $_
    $userId = az ad user show --id $userName --query "id" -o tsv
    $computeInstanceName = "azureailab{0:D2}ci" -f $_

    $ciYamlContent = $ciYamlTemplate.Replace("<NAME>", $computeInstanceName).Replace("<TENANT_ID>", $tenantId).Replace("<USER_ID>", $userId)
    Set-Content -Path "$($workspaceName)-ci.yaml" -Value $ciYamlContent

    az ml compute create --file "$($workspaceName)-ci.yaml" --resource-group $resourceGroupName --workspace-name $workspaceName --no-wait

    Remove-Item -Path "$($workspaceName)-ci.yaml"
}

# Create key vault secrets and access policies

$openAIAPIKey = "..."

(1..$workspaceCount) | ForEach-Object {
    $workspaceName = "azureailab{0:D2}" -f $_
    $resourceGroupName = $workspaceName
    $userName = "azureai-lab-{0:D2}@solliance.net" -f $_
    $userId = az ad user show --id $userName --query "id" -o tsv

    az keyvault set-policy --name $workspaceName --resource-group $resourceGroupName --object-id $userId --secret-permissions get list
    az keyvault secret set --name "open-ai-api-key" --vault-name $workspaceName --value $openAIAPIKey
}
