module "user_assigned_managed_identity" {
  source   = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version  = "0.5.0"
  for_each = local.environment_split

  location            = var.location
  name                = each.value.user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

locals {
  federated_credentials = { for federated_credential in flatten([for env_key, env_value in local.environment_split : [
    for template in env_value.required_templates : {
      composite_key                     = "${env_key}-${template}"
      user_assigned_managed_identity_id = module.user_assigned_managed_identity[env_key].resource_id
      subject                           = "repository_owner_id:${data.github_organization.this.id}:repository_id:${github_repository.this.repo_id}:environment:${env_key}:job_workflow_ref:${format(local.template_claim_structure, template)}"
    }
  ]]) : federated_credential.composite_key => federated_credential }
  template_claim_structure = "${var.github_organization_name}/${local.effective_template_repo_name}/.github/workflows/%s@refs/heads/main"
}

resource "azapi_resource" "federated_identity_credential" {
  for_each = local.federated_credentials

  name      = each.value.federated_credential_name
  parent_id = each.value.user_assigned_managed_identity_id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  body = {
    properties = {
      audiences = [local.default_audience_name]
      issuer    = local.github_issuer_url
      subject   = each.value.subject
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
