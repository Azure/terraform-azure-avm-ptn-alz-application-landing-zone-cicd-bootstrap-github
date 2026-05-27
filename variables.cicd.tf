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

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "The deployment mode for the module. Possible values are 'terraform', 'bicep', or 'other'. Only 'terraform' mode creates the storage account for Terraform state."

  validation {
    condition     = contains(["terraform", "bicep", "other"], var.deployment_mode)
    error_message = "deployment_mode must be 'terraform', 'bicep', or 'other'."
  }
}

variable "example_module_path" {
  type        = string
  default     = null
  description = "The absolute path to the example module to seed into the created repository."
}

variable "github_create_main_repository" {
  type        = bool
  default     = true
  description = "Whether to create and manage the main repository and repository-scoped CI/CD resources."
}

variable "github_create_template_repository" {
  type        = bool
  default     = true
  description = "Whether to create a template repository for CI/CD workflow templates. Set to false if you don't need a template repository."
}

variable "github_existing_template_repository_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing template repository containing CI/CD workflow templates (BYO mode). When set, the module will not create a template repository or push template files."
}

variable "github_workflow_folder_path" {
  type        = string
  default     = null
  description = "The absolute path to the folder containing workflow YAML files. When null, auto-selects based on `deployment_mode` (e.g. 'workflows/terraform' or 'workflows/bicep'). Set to a custom path to use your own workflow templates."
}

variable "github_workflows" {
  type = map(object({
    main_file     = string
    template_path = string
  }))
  default     = null
  description = <<DESCRIPTION
A map of workflows to create in the main repository. Each key is the workflow name, and the value specifies:
- `main_file` - The source YAML file name within the workflow folder's main/ directory.
- `template_path` - The path to the template within the template repository.
When null, defaults based on deployment_mode:
  terraform: { ci = { main_file = "workflows/ci.yaml", template_path = ".github/workflows/ci-template.yaml" }, cd = { main_file = "workflows/cd.yaml", template_path = ".github/workflows/cd-template.yaml" } }
  bicep: same structure
DESCRIPTION
}
