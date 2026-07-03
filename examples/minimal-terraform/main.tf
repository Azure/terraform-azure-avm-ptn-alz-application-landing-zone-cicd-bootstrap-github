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

resource "random_string" "workload" {
  length  = 4
  numeric = false
  special = false
  upper   = false
}

# This is the module call
module "test" {
  source = "../../"

  github_organization_name = var.github_organization_name
  location                 = var.location
  enable_telemetry         = var.enable_telemetry
  example_module_path      = "${path.root}/../../example-repos/terraform"
  resource_name_workload   = random_string.workload.result
  runner_use_self_hosted   = false
}
