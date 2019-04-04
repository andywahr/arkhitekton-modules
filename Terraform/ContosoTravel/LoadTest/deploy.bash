        export ARM_CLIENT_ID=$servicePrincipalId
        export ARM_CLIENT_SECRET=$servicePrincipalKey
        export ARM_SUBSCRIPTION_ID=$(az account show --query id | tr -d '"') 
        export ARM_TENANT_ID=$(az account show --query tenantId | tr -d '"')

        terraform init 
        terraform plan -var "namePrefix=$1" -var "resourceGroupName=$2"
        terraform apply -var "namePrefix=$1" -var "resourceGroupName=$2" -auto-approve