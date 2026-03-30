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

  location               = var.location
  github_organization_name      = var.github_organization_name
  enable_telemetry       = var.enable_telemetry
  deployment_mode        = "bicep"
  example_module_path    = "examples/example-module-bicep"
  compute_type = "azure_container_app"
  runner_use_self_hosted = true
}
