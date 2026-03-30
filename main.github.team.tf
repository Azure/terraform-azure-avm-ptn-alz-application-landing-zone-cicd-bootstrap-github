locals {
  approvers = local.create_approval_team ? [for user in data.github_organization.this.users : {
    id         = user.id
    login      = user.login
    email      = user.email
    matched_on = contains(values(var.approvers), user.email) ? user.email : (contains(values(var.approvers), user.login) ? user.login : "none")
  } if contains(values(var.approvers), user.email) || contains(values(var.approvers), user.login)] : []

  invalid_approvers = local.create_approval_team ? setsubtract(values(var.approvers), local.approvers[*].matched_on) : []
}

resource "github_team" "this" {
  count       = local.create_approval_team ? 1 : 0
  name        = local.resource_names.team_name
  description = "Approvers for the Landing Zone Terraform Apply"
  privacy     = "closed"

  lifecycle {
    precondition {
      condition     = length(local.invalid_approvers) == 0
      error_message = "At least one approver has not been supplied with a valid email. Invalid approvers: ${join(", ", local.invalid_approvers)}"
    }
  }
}

resource "github_team_membership" "this" {
  for_each = local.create_approval_team ? { for approver in local.approvers : approver.login => approver } : {}
  team_id  = github_team.this[0].id
  username = each.value.login
  role     = "member"
}

resource "github_team_repository" "this" {
  count      = local.create_approval_team ? 1 : 0
  team_id    = github_team.this[0].id
  repository = github_repository.this.name
  permission = "push"
}
