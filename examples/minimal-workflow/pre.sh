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
} > .env