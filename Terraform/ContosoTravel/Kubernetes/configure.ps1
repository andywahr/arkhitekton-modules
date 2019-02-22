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


kubectl apply -f init.yaml
$appInsightsKey=az resource show --resource-group $rg --subscription $sub --resource-type Microsoft.Insights/components --name YYYY --query "properties.InstrumentationKey"

if ( $includeNginx )
{
    helm init --service-account tiller
    helm repo update
    helm install stable/nginx-ingress --namespace kube-system --set controller.replicaCount=2 --set rbac.create=false
}

kubectl apply -f $pathToDeploy

