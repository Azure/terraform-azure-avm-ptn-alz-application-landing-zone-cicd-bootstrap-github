terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.5"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "github" {
  owner = var.github_organization_name
}

# Minimal example: single write identity, GitHub-hosted runners, no template repo, custom workflow
module "test" {
  source = "../../"

  location                = var.location
  github_organization_name = var.github_organization_name
  deployment_mode         = "other"
  runner_use_self_hosted  = false

  github_existing_template_repository_name = "not-used"

  github_workflow_folder_path = "workflows"
  github_workflows = {
    info = {
      main_file     = "workflows/info.yaml"
      template_path = ".github/workflows/info-template.yaml"
    }
  }

  environments = {
    dev = {
      display_order   = 1
      display_name    = "Development"
      scope           = "subscription"
      subscription_id = var.target_subscription_id
      identities = {
        read = { enabled = false }
      }
    }
  }
}
