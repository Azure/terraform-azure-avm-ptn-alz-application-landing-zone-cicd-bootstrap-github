# --- Repositories ---

variable "existing_template_repository_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing template repository containing CI/CD workflow templates (BYO mode). When set, the module will not create a template repository or push template files."
}

variable "example_module_path" {
  type        = string
  description = "The relative path to the example module to seed into the created repository."
  default     = null
}

# --- Deployment Mode ---

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "The deployment mode for the module. Possible values are 'terraform', 'bicep', or 'other'. Only 'terraform' mode creates the storage account for Terraform state."
  validation {
    condition     = contains(["terraform", "bicep", "other"], var.deployment_mode)
    error_message = "deployment_mode must be 'terraform', 'bicep', or 'other'."
  }
}

variable "bicep_deployments" {
  type = list(object({
    name                = string
    template_file       = string
    parameters_file     = optional(string)
    scope               = optional(string, "group")
    resource_group      = optional(string)
    location            = optional(string)
    management_group_id = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
A list of Bicep deployment stack configurations. Each deployment specifies a template file, optional parameters file, and scope.
- `name` - (Required) The name of the deployment stack.
- `template_file` - (Required) The relative path to the Bicep template file.
- `parameters_file` - (Optional) The relative path to the parameters file.
- `scope` - (Optional) The deployment scope: 'group' (resource group), 'sub' (subscription), or 'mg' (management group). Defaults to 'group'.
- `resource_group` - (Optional) The resource group name. Required when scope is 'group'.
- `location` - (Optional) The deployment location. Required when scope is 'sub' or 'mg'.
- `management_group_id` - (Optional) The management group ID. Required when scope is 'mg'.
DESCRIPTION
}

# --- Workflow Templates ---

variable "workflow_folder_path" {
  type        = string
  default     = null
  description = "The relative path to the folder containing workflow YAML files. When null, auto-selects based on `deployment_mode` (e.g. 'workflows/terraform' or 'workflows/bicep'). Set to a custom path to use your own workflow templates."
}

variable "ci_template_path" {
  type        = string
  default     = null
  description = "The path to the CI template within the template repository. When null, defaults to '.github/workflows/ci-template.yaml'."
}

variable "cd_template_path" {
  type        = string
  default     = null
  description = "The path to the CD template within the template repository. When null, defaults to '.github/workflows/cd-template.yaml'."
}
