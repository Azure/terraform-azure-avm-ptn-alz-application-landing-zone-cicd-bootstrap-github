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

# ACI with private networking and Terraform workflows
module "test" {
  source = "../../"

  github_organization_name = var.github_organization_name
  location                 = var.location
  compute_type             = "azure_container_instance"
  enable_telemetry         = var.enable_telemetry
  example_module_path      = "examples/example-module-terraform"
  runner_use_self_hosted   = true
}
