# GitHub CI/CD decision locals
locals {
  create_template_repository     = var.github_existing_template_repository_name == null
  effective_template_repo_name   = var.github_existing_template_repository_name != null ? var.github_existing_template_repository_name : github_repository.template[0].name
  effective_ci_template_path     = coalesce(var.github_ci_template_path, ".github/workflows/ci-template.yaml")
  effective_cd_template_path     = coalesce(var.github_cd_template_path, ".github/workflows/cd-template.yaml")
  create_approval_team           = var.github_existing_approvers_team_id == null && length(var.approvers) > 0
  effective_approvers_team_id    = var.github_existing_approvers_team_id != null ? var.github_existing_approvers_team_id : (local.create_approval_team ? github_team.this[0].id : null)
  has_approvers                  = var.github_existing_approvers_team_id != null || length(var.approvers) > 0
}
