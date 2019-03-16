param
(
      [Parameter(Mandatory=$true)]
      $rg,
      
      [Parameter(Mandatory=$true)]
      $sub,
      
      [Parameter(Mandatory=$true)]
      $namePrefix,

      [switch]$includeNginx,

      [Parameter(Mandatory=$true)]
      $pathToDeploy
)

"Get Credentials"
az aks get-credentials --resource-group $rg --subscription $sub --name ("aks-ContosoTravel-" + $namePrefix) --overwrite-existing

"Get Info From Resource Group - identity"
$id = az identity list --query [].id --output tsv  --resource-group $rg --subscription $sub
"Get Info From Resource Group - clientId"
$clientId = az identity list --query [].clientId --output tsv  --resource-group $rg --subscription $sub
"Get Info From Resource Group - appInsightsKey"
$appInsightsKey = az resource show --resource-group $rg --subscription $sub --resource-type Microsoft.Insights/components --name ($namePrefix +"appInsightContosoTravel") --query "properties.InstrumentationKey"
"Get Info From Resource Group - dnsZone"
$dnsZone = (az aks show --resource-group $rg --subscription $sub --name ("aks-ContosoTravel-" + $namePrefix) --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName).Replace('"', '')
"Get Info serviceConnStr Resource Group - dnsZone"
$serviceConnStr = (az keyvault secret show --subscription $sub --vault-name "kv$namePrefix" --name "ContosoTravel--EventingConnectionString" --query value).Replace('"', '')

# Get the id of the service principal configured for AKS
$CLIENT_ID=(az aks show --resource-group $rg --subscription $sub --name ("aks-ContosoTravel-" + $namePrefix) --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
$ACR_ID=$(az acr show --name ("acrContosoTravel" + $namePrefix) --resource-group $rg --subscription $sub --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID


function replaceInFiles([string]$fileName) {
  $contents = get-content $fileName | out-string
  $contents = $contents.Replace('$CLIENTID$', $clientId)
  $contents = $contents.Replace('$APPINSIGHTSKEY$', $appInsightsKey)
  $contents = $contents.Replace('$NAMEPREFIX$', $namePrefix)
  $contents = $contents.Replace('$DNSZONE$', $dnsZone)
  $contents = $contents.Replace('$SERVICECONNECTIONSTRING$', $serviceConnStr)
  $contents = $contents.Replace('$ID$', $id)
  set-content -Path $fileName -Value $contents -Force
}

replaceInFiles "$PSScriptRoot/init.yaml"
replaceInFiles $pathToDeploy

kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml
kubectl apply -f "$PSScriptRoot/init.yaml"

kubectl apply -f $pathToDeploy

