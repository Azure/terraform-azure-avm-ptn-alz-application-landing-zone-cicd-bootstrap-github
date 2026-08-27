# GitHub CI/CD Bootstrap for ALZ Application Landing Zones

This Azure Verified Module (AVM) pattern module bootstraps a complete, opinionated GitHub CI/CD environment for an Azure Landing Zone (ALZ) **application landing zone**. It provisions the GitHub platform surface (repositories, environments, action variables, optional runner group), the supporting Azure resources for Terraform / Bicep state and self-hosted runner compute, and wires per-environment OIDC federated credentials so application teams can deploy from day one with no long-lived secrets.

## Features

### GitHub platform

- **Repositories** — creates a main application repository in the target GitHub organization and an optional shared template repository for reusable workflow templates. Set `github_existing_template_repository_name` to attach to an existing template repo in BYO mode.
- **Workflows** — provisions CI / CD workflow files in the main repository. Auto-selects the workflow folder based on `deployment_mode` (`terraform` / `bicep` / `other`) or accepts a custom path. Both the workflow file names and template paths are user-overridable.
- **Environments & approvals** — creates one GitHub environment per logical environment (e.g. `dev`, `prod`) with reviewers / wait timers and environment-scoped secrets and variables.
- **Federated credentials** — registers federated identity credentials between the per-environment Azure UAMIs and each GitHub environment, so workflows authenticate to Azure with OIDC and no client secrets.
- **Action variables** — sets repository / environment-level GitHub Actions variables consumed by the workflows.
- **Team** — creates a GitHub team and grants it appropriate access on the bootstrapped repositories.
- **Runner group** — optionally creates a GitHub Actions runner group (requires GitHub Enterprise) and assigns the self-hosted runners to it.
- **Repository seeding** — optionally seeds the application repository with an example Terraform or Bicep module (`example_module_path`).

### Self-hosted runners

- **Compute choice** — deploys self-hosted runners on either **Azure Container Instances** (`azure_container_instance`) or **Azure Container Apps** (`azure_container_app`). Defaults to ACI.
- **Authentication** — supports two runner authentication methods:
  - `github_app` *(default, recommended)* — uses a GitHub App (configured via `var.github_app_id`, `var.github_app_installation_id`, `var.github_app_key`) to mint short-lived registration tokens for the runners. **No PAT required.**
  - `pat` *(legacy)* — uses a Personal Access Token supplied via `var.runner_personal_access_token`.
- **Bring-your-own** — set `runner_existing_group_name` to register runners against an existing group and skip all Azure compute provisioning, or set `runner_use_self_hosted = false` to use GitHub-hosted runners.
- **Availability zones** — optionally spread compute across zones (`runner_compute_use_availability_zones`).

### Azure resources

- **Terraform state & plan storage** — when `deployment_mode = "terraform"`, provisions a hardened storage account (private endpoint, no public access) for Terraform remote state per environment, and, when `use_storage_account_for_plan = true` (the default), a dedicated `<env>-tfplan` container per environment for secure plan hand-off between the CD `plan` and `apply` jobs.
- **Networking** — provisions a virtual network with dedicated subnets for runners and private endpoints, or accepts a pre-existing VNet / subnets in BYO mode.
- **Private DNS** — manages private DNS zones for private endpoints, with an opt-out (`azure_alz_platform_landing_zone_mode_enabled`) for ALZ platforms that manage DNS centrally via Azure Policy.
- **Identity** — creates the per-environment UAMIs used as the federation principals for each GitHub environment.
- **Resource groups** — creates dedicated resource groups for identity, state, runners, and networking (or reuses an existing VNet's resource group in BYO mode).

### Secure Terraform plan hand-off

- **Default-secure** — `use_storage_account_for_plan = true` by default. The CD `plan` job uploads the binary plan to a per-environment Blob container (`<env>-tfplan`) instead of bundling it into the GitHub Actions artifact; the `apply` job downloads the exact same blob by run ID and deletes it after a successful apply.
- **Legacy fallback** — set `use_storage_account_for_plan = false` to revert to shipping the plan inside the GitHub Actions build artifact. This is less secure (plan contents can include sensitive values and are retained per your org's Actions artifact retention policy) and is provided only for compatibility with self-managed/BYO template repos that haven't adopted the new templates.
- **Custom template repositories are not auto-secured** — if you set `github_existing_template_repository_name` or a custom `github_workflow_folder_path`, the module does not modify your workflow YAML. You must adopt the upload/download/delete steps yourself for storage-backed hand-off to apply.
- **`show_plan_in_pipeline_logs`** — defaults to `false`. Enabling it prints the full plan to the pipeline log, visible to anyone with read access to the repo/Actions runs. Only enable if your organization has explicitly accepted that exposure.
- **`plan_storage_retention_days`** (default `7`) — a storage lifecycle policy rule deletes abandoned plan blobs, snapshots, and previous versions after this many days. This is a backstop only; successful applies delete their own plan blob immediately.
- **Recoverability** — the plan container inherits the storage account's blob versioning/soft-delete settings, so an accidentally-deleted plan blob may still be recoverable within your soft-delete window.
- **Trusted-admin threat boundary** — this feature keeps plan contents out of GitHub Actions artifact storage. It does not protect against an Azure user with Storage Blob Data Contributor/Owner-equivalent access to the storage account — the same trust boundary as Terraform remote state.
- **Stale/concurrent plans** — the `apply` job always downloads the blob written by its own `plan` job run (keyed by run ID), never "the latest" blob, so a concurrent or superseded run cannot apply a stranger's plan.
- **Non-retroactive upgrade** — enabling this on an existing deployment only takes effect for the next `plan`/`apply` cycle; it does not migrate plans already in flight.
- **Upgrading an existing storage account** — `storage_management_policy_rule` replaces the account's *entire* lifecycle policy, not just this module's rules. If you already manage that storage account's lifecycle policy outside this module, applying this upgrade will silently overwrite those rules. Before upgrading, check existing rules with `az storage account management-policy show` and fold them into your Terraform config first.

## Authentication required to use the module

The module talks to two control planes: **Azure Resource Manager** and **GitHub**. Configure provider authentication via environment variables — the module itself does not accept any provider credentials as input variables.

### Azure (`azurerm`, `azapi`) provider

Recommended: **OIDC federation** via `ARM_USE_OIDC=true` plus `ARM_TENANT_ID`, `ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, and the OIDC token vars (`ARM_OIDC_REQUEST_TOKEN` / `ARM_OIDC_REQUEST_URL` in GitHub Actions). Service principal secret (`ARM_CLIENT_SECRET`) and `az login` are also supported.

The identity must hold **Owner** on the target subscription (or sufficient Contributor + User Access Administrator) because the module assigns RBAC to the per-environment UAMIs.

### GitHub (`integrations/github`) provider

Set `GITHUB_TOKEN` and `GITHUB_OWNER` in the environment. The token must be either:

- A **classic Personal Access Token** with at minimum the `repo`, `workflow`, `admin:org`, and `delete_repo` scopes, or
- A **fine-grained PAT** scoped to the target organization with equivalent repository and organization administration permissions, or
- A **GitHub App installation token** with the equivalent permissions.

If you set `runner_create_group = true` the token's organization must be on a **GitHub Enterprise** plan, since runner groups are an Enterprise feature.

`GITHUB_OWNER` should match `var.github_organization_name`.

### Legacy PAT (optional)

The only remaining token *input variable* is `var.runner_personal_access_token`, which is **only consumed when `var.runner_authentication_method = "pat"`** to register the self-hosted runners. With the default GitHub App authentication method this variable can be left `null`.
