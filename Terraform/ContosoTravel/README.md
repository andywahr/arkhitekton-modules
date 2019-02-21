# Terraform for Contoso Travel

## Make sure to create a temp_override.tf in this directory to test the overrides you want. For example:
````json
module "eventing" {
    source = "eventing/eventgrid"
}

module "data" {
  source = "data/sql" 
}

module "webSite" {
   source = "web/appservice"
}

module "service" {
    source = "backend/functions"
}

variable "namePrefix" {
  default = "adwter4"
}

variable "location" {
  default = "westus2"
}

variable "resourceGroupName" {
  default = "rg-adwter4"
}

variable "my_principal_object_id" {
  default = "(Your Object Id from Azure AD for testing only)"
}
````