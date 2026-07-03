#!/usr/bin/env bash
# Runs before the terraform steps for this example in AVM CI (well-architected plan
# and examples tests). It writes a .env file that the terraform steps auto-source, so
# values that must come from the environment are supplied without being committed.
# See: https://github.com/Azure/avm-terraform-governance/blob/main/porch-configs/README.md
set -euo pipefail

# This module requires a real, pre-existing GitHub organization because
# data.github_organization performs a live lookup at plan time. In AVM CI the target
# organization is provided via the AVM_E2E_GITHUB_ORGANIZATION_NAME secret; fall back to
# the ambient organization ("Azure") so `terraform plan` can always resolve.
github_organization_name="${AVM_E2E_GITHUB_ORGANIZATION_NAME:-Azure}"

{
  echo "TF_VAR_github_organization_name=${github_organization_name}"
  if [ -n "${AVM_E2E_GITHUB_TOKEN:-}" ]; then
    echo "GITHUB_TOKEN=${AVM_E2E_GITHUB_TOKEN}"
    echo "GITHUB_OWNER=${github_organization_name}"
  fi

  # Self-hosted runner registration uses GitHub App credentials. Real secrets are only
  # available in the examples/integration tests; the well-architected plan check runs
  # without them. terraform plan never authenticates with these values (they are passed
  # through to the agents module as strings), so when the real secrets are absent we emit
  # non-functional placeholders purely to satisfy variable validation. Any real
  # TF_VAR_github_app_* provided via the environment takes precedence and is left as-is
  # (the private key stays in the environment so its multi-line value is not written here).
  if [ -z "${TF_VAR_github_app_id:-}" ]; then
    echo "TF_VAR_github_app_id=123456"
  fi
  if [ -z "${TF_VAR_github_app_installation_id:-}" ]; then
    echo "TF_VAR_github_app_installation_id=654321"
  fi
  if [ -z "${TF_VAR_github_app_key:-}" ]; then
    echo "TF_VAR_github_app_key=placeholder-github-app-key-not-used-during-plan"
  fi
} > .env