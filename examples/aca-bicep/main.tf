terraform {
  required_version = "~> 1.9"

  required_providers {
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

# ACA with Bicep workflows
module "test" {
  source = "../../"

  github_organization_name = var.github_organization_name
  location                 = var.location
  deployment_mode          = "bicep"
  enable_telemetry         = var.enable_telemetry
  example_module_path      = "${path.root}/../../example-repos/bicep"
  runner_compute_type      = "azure_container_app"
  runner_use_self_hosted   = true
  resource_name_workload   = "acab"

  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_key             = var.github_app_key
}
