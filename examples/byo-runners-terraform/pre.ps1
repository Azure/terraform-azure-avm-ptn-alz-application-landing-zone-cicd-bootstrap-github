#!/usr/bin/env pwsh

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$organizationName = if ([string]::IsNullOrEmpty($env:AVM_E2E_GITHUB_ORGANIZATION_NAME)) {
  'Azure'
}
else {
  $env:AVM_E2E_GITHUB_ORGANIZATION_NAME
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("TF_VAR_github_organization_name=$organizationName")

if (-not [string]::IsNullOrEmpty($env:AVM_E2E_GITHUB_TOKEN)) {
  $lines.Add("GITHUB_TOKEN=$($env:AVM_E2E_GITHUB_TOKEN)")
  $lines.Add("GITHUB_OWNER=$organizationName")
}

$githubAppId = if (-not [string]::IsNullOrEmpty($env:TF_VAR_github_app_id)) {
  $env:TF_VAR_github_app_id
}
elseif (-not [string]::IsNullOrEmpty($env:AVM_E2E_GITHUB_APP_ID)) {
  $env:AVM_E2E_GITHUB_APP_ID
}
else {
  '123456'
}
$lines.Add("TF_VAR_github_app_id=$githubAppId")

$githubAppInstallationId = if (-not [string]::IsNullOrEmpty($env:TF_VAR_github_app_installation_id)) {
  $env:TF_VAR_github_app_installation_id
}
elseif (-not [string]::IsNullOrEmpty($env:AVM_E2E_GITHUB_APP_INSTALLATION_ID)) {
  $env:AVM_E2E_GITHUB_APP_INSTALLATION_ID
}
else {
  '654321'
}
$lines.Add("TF_VAR_github_app_installation_id=$githubAppInstallationId")

if ([string]::IsNullOrEmpty($env:TF_VAR_github_app_key)) {
  $githubAppKey = if ([string]::IsNullOrEmpty($env:AVM_E2E_GITHUB_APP_KEY)) {
    'placeholder-github-app-key-not-used-during-plan'
  }
  else {
    $env:AVM_E2E_GITHUB_APP_KEY
  }

  # The dotenv bridge is line-based; encode line endings and decode them at the module call.
  $encodedKey = $githubAppKey.Replace("`r`n", '\r\n').Replace("`n", '\n')
  $lines.Add("TF_VAR_github_app_key=$encodedKey")
}

$envPath = Join-Path $PSScriptRoot '.env'
[System.IO.File]::WriteAllLines($envPath, $lines, [System.Text.UTF8Encoding]::new($false))
