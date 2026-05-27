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

provider "github" {}

# GitHub-hosted runners with Terraform workflows (no self-hosted infra)
module "test" {
  source = "../../"

  github_organization_name = var.github_organization_name
  location                 = var.location
  enable_telemetry         = var.enable_telemetry
  example_module_path      = "${path.root}/../../example-repos/terraform"
  runner_use_self_hosted   = false
}
