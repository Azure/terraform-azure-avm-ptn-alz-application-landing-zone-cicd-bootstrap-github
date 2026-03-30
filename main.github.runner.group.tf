locals {
  use_runner_group = var.existing_runner_group_name == null && var.create_runner_group && data.github_organization.this.plan == local.enterprise_plan && var.use_self_hosted_agents
}

resource "github_actions_runner_group" "this" {
  count                   = local.use_runner_group ? 1 : 0
  name                    = local.resource_names.runner_group_name
  visibility              = "selected"
  selected_repository_ids = compact([github_repository.this.repo_id, local.create_template_repository ? github_repository.template[0].repo_id : ""])
}
