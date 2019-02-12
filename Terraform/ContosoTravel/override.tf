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