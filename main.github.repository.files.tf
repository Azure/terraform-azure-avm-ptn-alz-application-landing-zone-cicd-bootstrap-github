locals {
  default_commit_email = coalesce(local.primary_approver, "demouser@example.com")
  effective_workflow_folder = var.github_workflow_folder_path != null ? var.github_workflow_folder_path : (
    contains(["terraform", "bicep"], var.deployment_mode) ? "${path.module}/workflows/${var.deployment_mode}" : null
  )
  environment_replacements = { for environment_key, environment_value in local.environments : "${format("%03s", environment_value.display_order)}-${environment_key}" => {
    name                                         = lower(replace(environment_key, "-", ""))
    display_name                                 = environment_value.display_name
    runner_name                                  = local.is_self_hosted ? local.effective_runner_group_name : "ubuntu-latest"
    environment_name_read                        = "${environment_key}-read"
    environment_name_write                       = "${environment_key}-write"
    dependent_environment                        = environment_value.dependent_environment
    backend_azure_storage_account_container_name = environment_key
  } }
  files = local.template_folder != null ? { for file in fileset(local.template_folder, "**") : file => {
    name    = file
    content = file("${local.template_folder}/${file}")
  } } : {}
  main_repository_files = merge(local.files, local.pipeline_main_files)
  pipeline_main_files = local.pipeline_main_folder != null ? { for file in fileset(local.pipeline_main_folder, "**") : "${local.target_folder_name}/${file}" => {
    name    = file
    content = templatefile("${local.pipeline_main_folder}/${file}", local.pipeline_main_replacements)
  } } : {}
  pipeline_main_folder = local.effective_workflow_folder != null ? "${local.effective_workflow_folder}/main" : null
  pipeline_main_replacements = {
    environments                     = local.environment_replacements
    organization_name                = data.github_organization.this.login
    repository_name_templates        = local.effective_template_repo_name
    workflows                        = local.effective_workflows
    root_module_folder_relative_path = "."
    deployments                      = var.bicep_deployments != null ? var.bicep_deployments : []
  }
  pipeline_template_files = local.pipeline_template_folder != null ? { for file in fileset(local.pipeline_template_folder, "**") : "${local.target_folder_name}/${file}" => {
    name    = file
    content = file("${local.pipeline_template_folder}/${file}")
  } } : {}
  pipeline_template_folder = local.effective_workflow_folder != null ? "${local.effective_workflow_folder}/templates" : null
  pipeline_template_replacements = {
    environments = local.environment_replacements
  }
  primary_approver   = length(var.approvers) > 0 ? var.approvers[keys(var.approvers)[0]] : ""
  target_folder_name = ".github"
  template_folder    = var.example_module_path
}

resource "github_repository_file" "this" {
  for_each            = local.create_main_repository ? local.main_repository_files : {}
  repository          = github_repository.this[0].name
  file                = each.key
  content             = each.value.content
  commit_author       = local.default_commit_email
  commit_email        = local.default_commit_email
  commit_message      = "Add ${each.key} [skip ci]"
  overwrite_on_create = true
}

resource "github_repository_file" "template" {
  for_each            = local.create_main_repository && local.create_template_repository ? local.pipeline_template_files : {}
  repository          = github_repository.template[0].name
  file                = each.key
  content             = each.value.content
  commit_author       = local.default_commit_email
  commit_email        = local.default_commit_email
  commit_message      = "Add ${each.key} [skip ci]"
  overwrite_on_create = true
}
