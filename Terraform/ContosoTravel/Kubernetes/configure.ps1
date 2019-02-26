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

"Get Info From Resource Group"
$id = az identity list --query [].id --output tsv  --resource-group $rg --subscription $sub
$clientId = az identity list --query [].clientId --output tsv  --resource-group $rg --subscription $sub
$appInsightsKey = az resource show --resource-group $rg --subscription $sub --resource-type Microsoft.Insights/components --name ($namePrefix +"appInsightContosoTravel") --query "properties.InstrumentationKey"

function replaceInFiles([string]$fileName) {
  $contents = gc $fileName | out-string
  $contents = $contents.Replace('$CLIENTID$', $clientId)
  $contents = $contents.Replace('$ID$', $id)
  $contents = $contents.Replace('$APPINSIGHTSKEY$', $appInsightsKey)
  $contents = $contents.Replace('$NAMEPREFIX$', $namePrefix)
  sc -Path $fileName -Value $contents -Force
}

replaceInFiles "$PSScriptRoot\init.yaml"
replaceInFiles $pathToDeploy

kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml
kubectl apply -f "$PSScriptRoot\init.yaml"

if ( $includeNginx )
{
    helm init --service-account tiller
    helm repo update
    helm install stable/nginx-ingress --namespace kube-system --set controller.replicaCount=2 --set rbac.create=false
}

kubectl apply -f $pathToDeploy

