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
  template_claim_structure = "${data.github_organization.this.login}/${local.effective_template_repo_name}/%s@refs/heads/main"
}

resource "azapi_resource" "federated_identity_credential" {
  for_each = local.federated_credentials

  name      = each.value.federated_credential_name
  parent_id = each.value.user_assigned_managed_identity_id
  type      = var.resource_types.managedidentity_user_assigned_identities_federated_identity_credentials
  body = {
    properties = {
      audiences = [local.default_audience_name]
      issuer    = local.github_issuer_url
      subject   = each.value.subject
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.managedidentity_user_assigned_identities_federated_identity_credentials) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities_federated_identity_credentials : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
