output "approvers" {
  description = "The list of approvers matched from the organization."
  value       = local.approvers
}

output "managed_identity_client_ids" {
  description = "A map of managed identity client IDs for each environment split (plan/apply)."
  value       = local.create_main_repository ? { for env_key, env_value in local.environment_split : env_key => module.user_assigned_managed_identity[env_key].client_id } : {}
}

output "resource_id" {
  description = "The resource ID of the identity resource group, which is the anchor Azure resource created by this module to host the CI/CD managed identities."
  value       = module.resource_group["identity"].resource_id
}

output "runner_group_name" {
  description = "The GitHub Actions runner group name used by this deployment."
  value       = var.runner_existing_group_name != null ? var.runner_existing_group_name : (local.use_runner_group ? github_actions_runner_group.this[0].name : null)
}

output "subscription_id" {
  description = "The subscription ID."
  value       = data.azapi_client_config.current.subscription_id
}

output "subscription_name" {
  description = "The subscription display name."
  value       = data.azapi_resource_action.subscription[data.azapi_client_config.current.subscription_id].output.displayName
}

output "tenant_id" {
  description = "The tenant ID."
  value       = data.azapi_client_config.current.tenant_id
}
