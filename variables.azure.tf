# --- Virtual Network ---

variable "address_space" {
  type        = string
  description = "The virtual network address space."
  default     = "10.0.0.0/24"
}

variable "subnets_and_sizes" {
  type        = map(number)
  description = "The CIDR prefix sizes for subnets within the virtual network."
  default = {
    agents            = 27
    private_endpoints = 29
  }
}

variable "existing_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing virtual network (BYO mode). Must be set together with `existing_agents_subnet_resource_id` and `existing_private_endpoints_subnet_resource_id`. When set, the module will not create a virtual network or agents resource group."
}

variable "existing_agents_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for runners (BYO mode). The subnet must have the appropriate delegation for the chosen `compute_type`."
}

variable "existing_private_endpoints_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for private endpoints (BYO mode)."
}

# --- Self-Hosted Runners ---

variable "use_self_hosted_agents" {
  type        = bool
  description = "Whether to use self-hosted runners. When false, workflows use GitHub-hosted runners."
  default     = true
}

variable "existing_runner_group_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing GitHub Actions runner group (BYO mode). When set, the module will not create a runner group or any Azure compute infrastructure. The provided group name will be used in workflow YAML files."
}

variable "create_runner_group" {
  type        = bool
  description = "Whether to create a runner group for the self-hosted runners. Requires a GitHub Enterprise organization."
  default     = false
}

variable "compute_type" {
  type        = string
  description = "The type of Azure compute to use for self-hosted runners. Must be either 'azure_container_app' or 'azure_container_instance'."
  default     = "azure_container_instance"
  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.compute_type)
    error_message = "compute_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "compute_use_availability_zones" {
  type        = bool
  default     = false
  description = "Use availability zones for the compute instances. This is off by default due to faults in various regions at time of authoring."
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
  sensitive   = true
  description = "The private key for GitHub App authentication. Required when `runner_authentication_method` is 'github_app'."
}

# --- Storage / Private Networking ---

variable "alz_platform_landing_zone_mode_enabled" {
  type        = bool
  default     = false
  description = "When enabled, the module will not create private DNS zones and will not manage DNS zone groups for private endpoints. This is useful when the platform landing zone is managing DNS zones centrally via Azure Policy."
}
