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
  owner = var.organization_name
}

# ACA with private networking and Terraform workflows
module "test" {
  source = "../../"

  location               = var.location
  organization_name      = var.organization_name
  enable_telemetry       = var.enable_telemetry
  example_module_path    = "examples/terraform-example-module"
  self_hosted_agent_type = "azure_container_app"
  use_self_hosted_agents = true
}
