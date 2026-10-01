#!/usr/bin/env pwsh

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.env') -Force -ErrorAction SilentlyContinue
