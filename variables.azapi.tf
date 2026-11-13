variable "ignore_body_changes" {
  type = object({
    authorization_role_assignments                                          = optional(list(string), [])
    managedidentity_user_assigned_identities_federated_identity_credentials = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths to ignore for the module's directly managed Azure resources. Ignored configuration is not sent to Azure until the path is removed. Changes take effect only after apply. Non-empty lists require Terraform 1.11 or later.

- `authorization_role_assignments` - Paths ignored on role assignments for existing deployment scopes.
- `managedidentity_user_assigned_identities_federated_identity_credentials` - Paths ignored on GitHub federated identity credentials.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_role_assignments                                          = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    managedidentity_user_assigned_identities_federated_identity_credentials = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31")
  })
  default     = {}
  description = <<DESCRIPTION
Resource types and API versions for the module's directly managed Azure resources.

- `authorization_role_assignments` - Type and API version for role assignments for existing deployment scopes.
- `managedidentity_user_assigned_identities_federated_identity_credentials` - Type and API version for GitHub federated identity credentials.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default = {
    error_message_regex = ["ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity"]
  }
  description = <<DESCRIPTION
Retry configuration for the module's directly managed Azure resources. Defaults to retrying concurrent federated credential writes for a managed identity. Set to null to use provider defaults.

- `error_message_regex` - Error patterns that trigger a retry.
- `interval_seconds` - Initial retry interval in seconds.
- `max_interval_seconds` - Maximum retry interval in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Operation timeouts for the module's directly managed Azure resources. Defaults to provider timeouts. Values are duration strings such as `30m` or `1h`.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
