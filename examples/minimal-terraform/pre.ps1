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

$envPath = Join-Path $PSScriptRoot '.env'
[System.IO.File]::WriteAllLines($envPath, $lines, [System.Text.UTF8Encoding]::new($false))
