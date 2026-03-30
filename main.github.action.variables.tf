resource "github_actions_environment_variable" "azure_client_id" {
  for_each      = local.environment_split
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "AZURE_CLIENT_ID"
  value         = module.user_assigned_managed_identity[each.key].client_id
}

resource "github_actions_environment_variable" "azure_subscription_id" {
  for_each      = local.environment_split
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = local.environments[each.value.environment].subscription_id
}

resource "github_actions_environment_variable" "azure_tenant_id" {
  for_each      = local.environment_split
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "AZURE_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_environment_variable" "backend_azure_storage_account_name" {
  for_each      = var.deployment_mode == "terraform" ? local.environment_split : {}
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "BACKEND_AZURE_STORAGE_ACCOUNT_NAME"
  value         = module.storage_account[0].name
}

resource "github_actions_environment_variable" "backend_azure_storage_account_container_name" {
  for_each      = var.deployment_mode == "terraform" ? local.environment_split : {}
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
  value         = each.value.environment
}

resource "github_actions_environment_variable" "additional_variables" {
  for_each      = var.deployment_mode == "terraform" ? local.environment_split : {}
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "ADDITIONAL_ENVIRONMENT_VARIABLES"
  value = jsonencode(merge(
    local.environments[each.value.environment].create_resource_group ? {
      TF_VAR_resource_group_name = module.resource_group_environments[each.value.environment].name
    } : {},
    local.environments[each.value.environment].scope == "subscription" || local.environments[each.value.environment].scope == "management_group" ? {
      TF_VAR_subscription_id = local.environments[each.value.environment].subscription_id
    } : {},
  ))
}

resource "github_actions_environment_variable" "var_file" {
  for_each      = var.deployment_mode == "terraform" ? local.environment_split : {}
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "VAR_FILE_PATH"
  value         = "./config/${each.value.environment}.tfvars"
}

resource "github_actions_environment_variable" "bicep_deployments" {
  for_each      = var.deployment_mode == "bicep" ? local.environment_split : {}
  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.key].environment
  variable_name = "BICEP_DEPLOYMENTS"
  value         = var.bicep_deployments != null ? jsonencode(var.bicep_deployments) : "[]"
}
