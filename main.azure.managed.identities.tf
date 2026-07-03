module "user_assigned_managed_identity" {
  source   = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version  = "0.5.0"
  for_each = local.create_main_repository ? local.environment_split : {}

  location            = var.location
  name                = each.value.user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

locals {
  federated_credentials = merge(local.federated_credentials_with_templates, local.federated_credentials_without_templates)
  federated_credentials_with_templates = local.create_main_repository ? { for federated_credential in flatten([for env_key, env_value in local.environment_split : [
    for template in env_value.required_templates : {
      composite_key                     = "${env_key}-${template}"
      federated_credential_name         = "${env_value.federated_credential_name}-${substr(sha1(template), 0, 8)}"
      user_assigned_managed_identity_id = module.user_assigned_managed_identity[env_key].resource_id
      subject                           = "repository_owner_id:${data.github_organization.this.id}:repository_id:${github_repository.this[0].repo_id}:environment:${env_key}:job_workflow_ref:${format(local.template_claim_structure, template)}"
    }
  ]]) : federated_credential.composite_key => federated_credential } : {}
  federated_credentials_without_templates = local.create_main_repository ? { for env_key, env_value in local.environment_split : env_key => {
    composite_key                     = env_key
    federated_credential_name         = env_value.federated_credential_name
    user_assigned_managed_identity_id = module.user_assigned_managed_identity[env_key].resource_id
    subject                           = "repository_owner_id:${data.github_organization.this.id}:repository_id:${github_repository.this[0].repo_id}:environment:${env_key}"
  } if length(env_value.required_templates) == 0 } : {}
  template_claim_structure = "${data.github_organization.this.login}/${local.effective_template_repo_name}/.github/workflows/%s@refs/heads/main"
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

  # Azure serialises federated identity credential writes per managed identity. This module creates
  # multiple credentials per user-assigned identity (one per environment / workflow template), which
  # Terraform applies in parallel, triggering a 409
  # "ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity". Retry (with the provider's
  # default backoff + randomisation, which desynchronises sibling writers) so the credentials serialise
  # and eventually succeed without failing the run.
  retry = {
    error_message_regex = ["ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity"]
  }
}
