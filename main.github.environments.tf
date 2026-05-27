locals {
  write_key = "write"
}

resource "github_repository_environment" "this" {
  for_each    = local.create_main_repository ? local.environment_split : {}
  environment = each.key
  repository  = github_repository.this[0].name

  dynamic "reviewers" {
    for_each = each.value.type == local.write_key && each.value.has_approval && local.has_approvers ? [1] : []
    content {
      teams = [
        local.effective_approvers_team_id
      ]
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.type == local.write_key ? [1] : []
    content {
      protected_branches     = true
      custom_branch_policies = false
    }
  }
}
