# GitHub CI/CD decision locals
locals {
  create_approval_team         = var.github_existing_approvers_team_id == null && length(var.approvers) > 0
  create_template_repository   = var.github_existing_template_repository_name == null
  effective_approvers_team_id  = var.github_existing_approvers_team_id != null ? var.github_existing_approvers_team_id : (local.create_approval_team ? github_team.this[0].id : null)
  effective_template_repo_name = var.github_existing_template_repository_name != null ? var.github_existing_template_repository_name : github_repository.template[0].name
  effective_workflows = coalesce(var.github_workflows, {
    ci = { main_file = "workflows/ci.yaml", template_path = ".github/workflows/ci-template.yaml" }
    cd = { main_file = "workflows/cd.yaml", template_path = ".github/workflows/cd-template.yaml" }
  })
  has_approvers = var.github_existing_approvers_team_id != null || length(var.approvers) > 0
}
