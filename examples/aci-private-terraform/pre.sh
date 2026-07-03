#!/usr/bin/env bash
# The github provider requires GITHUB_TOKEN in the environment. It is supplied
# via the AVM_E2E_GITHUB_TOKEN secret (non-TF_VAR_ env var) so that TF_VAR_*
# token variables are limited to legacy PAT support for runner registration
# via var.runner_personal_access_token.
#
# Porch runs each hook and terraform step in its own subprocess, so exporting
# the variable here would not reach the terraform steps. Instead we write a
# .env file, which the terraform init/plan steps auto-source.
set -euo pipefail

if [ -n "${AVM_E2E_GITHUB_TOKEN:-}" ]; then
  cat > .env <<EOF
GITHUB_TOKEN=${AVM_E2E_GITHUB_TOKEN}
EOF
fi