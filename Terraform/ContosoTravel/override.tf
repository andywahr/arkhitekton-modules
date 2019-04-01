module "eventing" {
    source = "eventing/#{eventing}#"
}

module "data" {
  source = "data/#{data}#" 
}

module "webSite" {
   source = "web/#{web}#"
}

module "service" {
    source = "backend/#{backend}#"
}

variable "namePrefix" {
  type = "string"
  default = "#{namePrefix}#"
}

variable "location" {
  type = "string"
  default = "#{location}#"
}

variable "cdn" {
  type    = "string"
  default = "#{cdn}#"
}

variable "trafficmanager" {
  type    = "string"
  default = "#{trafficmanager}#"
}

variable "apimgmt" {
  type    = "string"
  default = "#{apimgmt}#"
}

variable "firewall" {
  type    = "string"
  default = "#{firewall}#"
}

variable "appgateway" {
  type    = "string"
  default = "#{appgateway}#"
}

variable "mobile" {
  type    = "string"
  default = "#{mobile}#"
}

variable "adb2c" {
  type    = "string"
  default = "#{adb2c}#"
}

variable "streamanalytics" {
  type    = "string"
  default = "#{streamanalytics}#"
}

variable "cognitiveservices" {
  type    = "string"
  default = "#{cognitiveservices}#"
}

variable "sqldatawarehouse" {
  type    = "string"
  default = "#{sqldatawarehouse}#"
}

variable "hdinsight" {
  type    = "string"
  default = "#{hdinsight}#"
}

variable "search" {
  type    = "string"
  default = "#{search}#"
}

variable "bot" {
  type    = "string"
  default = "#{bot}#"
}

variable "resourceGroupName" {
  type = "string"
  default = "#{resourceGroupName}#"
}

variable "servicePrincipalObjectId" {
  type = "string"
  default = "#{servicePrincipalObjectId}#"
}

variable "servicePrincipalClientId" {
  type = "string"
  default = "#{servicePrincipalClientId}#"
}

variable "servicePrincipalSecretName" {
  type = "string"
  default = "#{servicePrincipalSecretName}#"
}

variable "web" {
  type = "string"
  default = "#{web}#"
}

variable "web_platform" {
  type = "string"
  default = "#{web_platform}#"
}

variable "backend" {
  type = "string"
  default = "#{backend}#"
}

variable "backend_platform" {
  type = "string"
  default = "#{backend_platform}#"
}