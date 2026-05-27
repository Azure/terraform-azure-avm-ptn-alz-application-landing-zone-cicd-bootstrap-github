locals {
  use_runner_group = var.runner_existing_group_name == null && var.runner_create_group && data.github_organization.this.plan == local.enterprise_plan && var.runner_use_self_hosted
}

resource "github_actions_runner_group" "this" {
  count                   = local.use_runner_group ? 1 : 0
  name                    = local.resource_names.runner_group_name
  visibility              = local.create_main_repository ? "selected" : "all"
  selected_repository_ids = local.create_main_repository ? compact([github_repository.this[0].repo_id, local.create_template_repository ? github_repository.template[0].repo_id : ""]) : []
}
