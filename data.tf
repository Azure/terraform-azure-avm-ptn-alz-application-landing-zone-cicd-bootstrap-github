data "azapi_client_config" "current" {}

data "azapi_resource_action" "current_subscription" {
  action                 = ""
  method                 = "GET"
  resource_id            = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  response_export_values = ["displayName"]
}

data "github_organization" "this" {
  name = var.github_organization_name
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"
}
