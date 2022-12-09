az login
az account set -s "Microsoft Azure Enterprise"
az account show

$providerState = az provider show --namespace "microsoft.ConfidentialLedger" --query registrationState -o tsv
if ($providerState -eq "NotRegistered") {
    az provider register --namespace "microsoft.ConfidentialLedger"
    az provider show --namespace "microsoft.ConfidentialLedger" --query registrationState -o tsv
}

