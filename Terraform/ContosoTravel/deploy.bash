        export ARM_CLIENT_ID=$servicePrincipalId
        export ARM_CLIENT_SECRET=$servicePrincipalKey
        export ARM_SUBSCRIPTION_ID=$(az account show --query id | tr -d '"') 
        export ARM_TENANT_ID=$(az account show --query tenantId | tr -d '"')

        terraform init 
        terraform plan 
        terraform apply -auto-approve