terraform {
  required_version = "~> 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    storage {
      data_plane_available = false
    }
  }
  storage_use_azuread = true
}

provider "github" {
  owner = var.github_organization_name
}

data "azapi_client_config" "current" {}

# Minimal example: single write identity, GitHub-hosted runners, no template repo, custom workflow
module "test" {
  source = "../../"

  github_organization_name = var.github_organization_name
  location                 = var.location
  deployment_mode          = "other"
  environments = {
    dev = {
      display_order   = 1
      display_name    = "Development"
      scope           = "subscription"
      subscription_id = data.azapi_client_config.current.subscription_id
      identities = {
        read = { enabled = false }
      }
    }
  }
  github_create_template_repository = false
  github_workflow_folder_path       = "${path.root}/workflows"
  github_workflows = {
    info = {
      main_file     = "workflows/info.yaml"
      template_path = ".github/workflows/info-template.yaml"
    }
  }
  runner_use_self_hosted = false
  resource_name_workload = "minw"
}
