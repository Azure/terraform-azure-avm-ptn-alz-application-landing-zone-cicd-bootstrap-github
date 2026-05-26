#!/usr/bin/env pwsh
# The github provider requires GITHUB_TOKEN in the environment. It is supplied
# via the AVM_E2E_GITHUB_TOKEN secret (non-TF_VAR_ env var) so that TF_VAR_*
# token variables are limited to legacy PAT support for runner registration
# via var.runner_personal_access_token.
if ($env:AVM_E2E_GITHUB_TOKEN) {
    $env:GITHUB_TOKEN = $env:AVM_E2E_GITHUB_TOKEN
}
