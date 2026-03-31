# --- Virtual Network ---

# --- Self-Hosted Runners ---

# --- Storage / Private Networking ---

variable "azure_address_space" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The virtual network address space."
}

variable "azure_alz_platform_landing_zone_mode_enabled" {
  type        = bool
  default     = false
  description = "When enabled, the module will not create private DNS zones and will not manage DNS zone groups for private endpoints. This is useful when the platform landing zone is managing DNS zones centrally via Azure Policy."
}

variable "azure_existing_private_endpoints_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for private endpoints (BYO mode)."
}

variable "azure_existing_runners_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for runners (BYO mode). The subnet must have the appropriate delegation for the chosen `compute_type`."
}

variable "azure_existing_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing virtual network (BYO mode). Must be set together with `existing_agents_subnet_resource_id` and `existing_private_endpoints_subnet_resource_id`. When set, the module will not create a virtual network or agents resource group."
}

variable "azure_subnets_and_sizes" {
  type = map(number)
  default = {
    agents            = 27
    private_endpoints = 29
  }
  description = "The CIDR prefix sizes for subnets within the virtual network."
}

variable "github_app_id" {
  type        = string
  default     = null
  description = "The application ID for GitHub App authentication. Required when `runner_authentication_method` is 'github_app'."
}

variable "github_app_installation_id" {
  type        = string
  default     = null
  description = "The installation ID for GitHub App authentication. Required when `runner_authentication_method` is 'github_app'."
}

variable "github_app_key" {
  type        = string
  default     = null
  description = "The private key for GitHub App authentication. Required when `runner_authentication_method` is 'github_app'."
  sensitive   = true
}

variable "runner_authentication_method" {
  type        = string
  default     = "github_app"
  description = "The authentication method for self-hosted runners. Possible values are 'pat' or 'github_app'. GitHub App authentication does not require a PAT for runner registration."

  validation {
    condition     = contains(["pat", "github_app"], var.runner_authentication_method)
    error_message = "runner_authentication_method must be 'pat' or 'github_app'."
  }
}

variable "runner_compute_type" {
  type        = string
  default     = "azure_container_instance"
  description = "The type of Azure compute to use for self-hosted runners. Must be either 'azure_container_app' or 'azure_container_instance'."

  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.runner_compute_type)
    error_message = "compute_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "runner_compute_use_availability_zones" {
  type        = bool
  default     = false
  description = "Use availability zones for the compute instances. This is off by default due to faults in various regions at time of authoring."
}

variable "runner_create_group" {
  type        = bool
  default     = false
  description = "Whether to create a runner group for the self-hosted runners. Requires a GitHub Enterprise organization."
}

variable "runner_existing_group_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing GitHub Actions runner group (BYO mode). When set, the module will not create a runner group or any Azure compute infrastructure. The provided group name will be used in workflow YAML files."
}

variable "runner_use_self_hosted" {
  type        = bool
  default     = true
  description = "Whether to use self-hosted runners. When false, workflows use GitHub-hosted runners."
}
