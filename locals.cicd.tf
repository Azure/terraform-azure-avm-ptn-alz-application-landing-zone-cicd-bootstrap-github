# GitHub CI/CD decision locals
locals {
  create_approval_team        = var.github_existing_approvers_team_id == null && length(var.approvers) > 0
  create_main_repository      = var.github_create_main_repository
  create_template_repository  = local.create_main_repository && var.github_create_template_repository && var.github_existing_template_repository_name == null
  effective_approvers_team_id = var.github_existing_approvers_team_id != null ? var.github_existing_approvers_team_id : (local.create_approval_team ? github_team.this[0].id : null)
  effective_template_repo_name = var.github_existing_template_repository_name != null ? var.github_existing_template_repository_name : (
    local.create_template_repository ? github_repository.template[0].name : ""
  )
  effective_workflows = coalesce(var.github_workflows, {
    ci = { main_file = "workflows/ci.yaml", template_path = ".github/workflows/ci-template.yaml" }
    cd = { main_file = "workflows/cd.yaml", template_path = ".github/workflows/cd-template.yaml" }
  })
  has_approvers     = var.github_existing_approvers_team_id != null || length(var.approvers) > 0
  has_template_repo = var.github_existing_template_repository_name != null || local.create_template_repository

  plan_storage_container_backend_collisions = [
    for container_name in values(local.plan_storage_container_names) : container_name
    if contains(keys(local.environments), container_name)
  ]
  plan_storage_container_duplicate_names = [
    for name in distinct(values(local.plan_storage_container_names)) : name
    if length([for v in values(local.plan_storage_container_names) : v if v == name]) > 1
  ]
  plan_storage_container_names = var.deployment_mode == "terraform" && var.use_storage_account_for_plan ? { for env_key, env_value in local.environments : env_key => (
    length(env_key) <= 56 ? "${env_key}-tfplan" : "tfplan-${substr(sha256(env_key), 0, 32)}"
  ) } : {}
}
