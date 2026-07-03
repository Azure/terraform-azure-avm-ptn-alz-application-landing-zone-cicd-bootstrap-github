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

locals {
  byo_environment  = "test"
  byo_workload     = "byob"
  seed_environment = "seed"
  seed_workload    = "byrg"
}

# Seed deployment: create self-hosted runner infrastructure including a runner group.
module "seed" {
  source = "../../"

  github_organization_name          = var.github_organization_name
  location                          = var.location
  enable_telemetry                  = var.enable_telemetry
  github_create_main_repository     = false
  github_create_template_repository = false
  resource_name_environment         = local.seed_environment
  resource_name_workload            = local.seed_workload
  runner_create_group               = true

  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_key             = var.github_app_key
}

# BYO deployment: consume the runner group from the seed module.
module "test" {
  source = "../../"

  github_organization_name   = var.github_organization_name
  location                   = var.location
  enable_telemetry           = var.enable_telemetry
  example_module_path        = "${path.root}/../../example-repos/terraform"
  resource_name_environment  = local.byo_environment
  resource_name_workload     = local.byo_workload
  runner_existing_group_name = module.seed.runner_group_name

  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_key             = var.github_app_key
}
