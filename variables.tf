variable "github_organization_name" {
  type        = string
  description = "The name of the GitHub organization."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,38}$", var.github_organization_name))
    error_message = "github_organization_name must be a valid GitHub organization name (1-39 chars, alphanumerics and hyphens, must start with alphanumeric)."
  }
}

variable "location" {
  type        = string
  description = "The location/region where the resources will be created. Must be in the short form (e.g. 'uksouth')"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "The location must only contain lowercase letters, numbers, and hyphens"
  }
  validation {
    condition     = length(var.location) <= 20
    error_message = "The location must be 20 characters or less"
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "github_organization_domain_name" {
  type        = string
  default     = "github.com"
  description = "The domain of the GitHub organization. Use `github.com` for GitHub.com or an enterprise subdomain ending in `.ghe.com` for GitHub Enterprise Cloud with data residency. Configure the GitHub provider API base URL in the calling configuration for GHE.com."
  nullable    = false

  validation {
    condition     = var.github_organization_domain_name == "github.com" || can(regex("^([A-Za-z0-9][A-Za-z0-9-]*\\.)+ghe\\.com$", var.github_organization_domain_name))
    error_message = "github_organization_domain_name must be 'github.com' or a GHE.com enterprise subdomain such as 'contoso.ghe.com'."
  }
}

variable "runner_personal_access_token" {
  type        = string
  default     = null
  description = "The personal access token for the GitHub organization. Required for runner authentication when `runner_authentication_method` is 'pat'. Provider auth should be configured via the GITHUB_TOKEN environment variable."
  sensitive   = true

  validation {
    condition     = !(var.runner_use_self_hosted && var.runner_authentication_method == "pat") || var.runner_personal_access_token != null
    error_message = "runner_personal_access_token must be set when runner_use_self_hosted is true and runner_authentication_method is 'pat'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
