mock_provider "github" {
  alias = "mock"

  mock_data "github_organization" {
    defaults = {
      id    = "12345678"
      login = "alz-test"
      plan  = "enterprise"
      users = []
    }
  }
}

mock_provider "modtm" {
  alias = "mock"
}

mock_provider "random" {
  alias = "mock"
}

provider "azapi" {
  alias = "test"
}

provider "azurerm" {
  alias = "test"

  features {}
}

override_data {
  target = data.azapi_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    object_id       = "00000000-0000-0000-0000-000000000002"
    client_id       = "00000000-0000-0000-0000-000000000003"
  }
}

override_data {
  target = data.azapi_resource_action.subscription
  values = {
    output = {
      displayName = "ALZ Test Subscription"
    }
  }
}

override_resource {
  target = azapi_resource.federated_identity_credential
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test/federatedIdentityCredentials/fic-test"
  }
}

override_module {
  target = module.user_assigned_managed_identity
  outputs = {
    client_id    = "00000000-0000-0000-0000-000000000003"
    principal_id = "00000000-0000-0000-0000-000000000002"
    resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"
  }
}

override_module {
  target = module.resource_group
  outputs = {
    name        = "rg-test"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  }
}

override_module {
  target = module.resource_group_environments
  outputs = {
    name        = "rg-test-env"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-env"
  }
}

override_module {
  target = module.role_definitions
  outputs = {
    role_definition_rolename_to_name = {
      Reader      = "00000000-0000-0000-0000-000000000004"
      Contributor = "00000000-0000-0000-0000-000000000005"
    }
  }
}

variables {
  github_organization_name = "alz-test"
  location                 = "eastus"
  deployment_mode          = "other"
  enable_telemetry         = false
  runner_use_self_hosted   = false
}

run "github_com_issuer_default" {
  command = apply
  providers = {
    azapi   = azapi.test
    azurerm = azurerm.test
    github  = github.mock
    modtm   = modtm.mock
    random  = random.mock
  }

  assert {
    condition = length(azapi_resource.federated_identity_credential) > 0 && alltrue([
      for credential in values(azapi_resource.federated_identity_credential) :
      credential.body.properties.issuer == "https://token.actions.githubusercontent.com"
    ])
    error_message = "The default GitHub.com domain must preserve the GitHub.com Actions issuer."
  }
}

run "ghe_com_issuer" {
  command = apply
  providers = {
    azapi   = azapi.test
    azurerm = azurerm.test
    github  = github.mock
    modtm   = modtm.mock
    random  = random.mock
  }

  variables {
    github_organization_domain_name = "contoso.ghe.com"
  }

  assert {
    condition = length(azapi_resource.federated_identity_credential) > 0 && alltrue([
      for credential in values(azapi_resource.federated_identity_credential) :
      credential.body.properties.issuer == "https://token.actions.contoso.ghe.com"
    ])
    error_message = "A GHE.com organization domain must select its dedicated Actions issuer."
  }
}

run "rejects_multi_label_ghe_domain" {
  command = plan
  providers = {
    azapi   = azapi.test
    azurerm = azurerm.test
    github  = github.mock
    modtm   = modtm.mock
    random  = random.mock
  }

  variables {
    github_organization_domain_name = "a.b.ghe.com"
  }

  expect_failures = [var.github_organization_domain_name]
}
