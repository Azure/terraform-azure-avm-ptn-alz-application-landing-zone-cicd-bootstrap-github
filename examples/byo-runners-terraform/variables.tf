variable "github_organization_name" {
  type        = string
  description = "The name of the GitHub organization."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "The location/region where the resources will be created."
}

variable "github_app_id" {
  type        = string
  default     = null
  description = "The application ID for GitHub App authentication."
}

variable "github_app_installation_id" {
  type        = string
  default     = null
  description = "The installation ID for GitHub App authentication."
}

variable "github_app_key" {
  type        = string
  default     = null
  description = "The private key for GitHub App authentication."
  sensitive   = true
}
