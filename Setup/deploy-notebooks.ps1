# Ensure azcopy exists in the .azure folder in the root of the repo directory

az login
az account set -s "Microsoft Azure Enterprise"
az account show

(1..35) | ForEach-Object {
    $workspaceName = "azureailab{0:D2}" -f $_
    $resourceGroupName = $workspaceName
    $userName = "azureai-lab-{0:D2}" -f $_
    $userId = az ad user show --id $userName --query "id" -o tsv
    $storageAccountName = $workspaceName

    $key = az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query [0].value -o tsv
    $fileShareName = az storage share list --account-key $key --account-name $storageAccountName --prefix "code-" --query [0].name -o tsv
    $fileShareSAS = az storage share generate-sas --account-key $key --account-name $storageAccountName --expiry "2037-12-31T23:59:00Z" --name $fileShareName --permissions dlrw -o tsv

    $destination = "https://$($storageAccountName).file.core.windows.net/${fileShareName}/Users/$($userName)?${fileShareSAS}"

    Write-Output "Deploying notebooks to ${destination}"

    .azure\azcopy copy ".\Lab 1\" $destination --overwrite=true --from-to=LocalFile --put-md5 --follow-symlinks --preserve-smb-info=false --recursive
    .azure\azcopy copy ".\Lab 2\" $destination --overwrite=true --from-to=LocalFile --put-md5 --follow-symlinks --preserve-smb-info=false --recursive
    .azure\azcopy copy ".\Lab 3\" $destination --overwrite=true --from-to=LocalFile --put-md5 --follow-symlinks --preserve-smb-info=false --recursive
}


