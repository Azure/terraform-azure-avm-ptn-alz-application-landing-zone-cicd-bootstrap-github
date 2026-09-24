#Requires -Version 7.4
<#
.SYNOPSIS
    Contract tests for the secure Terraform plan storage feature (issue #4174)
    as implemented in the CI/CD workflow templates.
.DESCRIPTION
    Statically inspects ci-template.yaml and cd-template.yaml and proves,
    without needing Azure/GitHub credentials or a live pipeline run, that the
    documented security contract for plan hand-off still holds in the
    template SOURCE:
      - the same computed container + an execution-bound (not attempt-bound)
        blob key is used across upload/download/delete
      - working directories only ever use $env:RUNNER_TEMP
      - the plan file is excluded from the (unencrypted) build artifact when
        secure storage is enabled, and the legacy fallback still copies it in
        explicitly when secure storage is disabled
      - cleanup steps always run, even on failure
      - the two feature flags are always compared with exact 'true' strings
      - blob keys never embed the run attempt number
      - there is no blob listing, no "latest" blob convention, and no
        shared-key ("--account-key") auth anywhere
      - every blob operation uses --auth-mode login, the upload is verified
        by content-length comparison, and all three operations are
        bounded-retry loops (not unbounded)
      - no plan JSON ever ships in the build artifact
      - upload/download failures fail closed (throw); a post-success delete
        failure fails open (warns only, so a completed apply is never marked
        failed just because blob cleanup could not run)
    This is a static contract test, not an execution test: it proves the
    template TEXT matches the contract. It does not prove runtime behavior -
    that is the job of the runtime-evidence gate.
.PARAMETER RepoRoot
    Path to the module root. Defaults to two levels above this script
    (tests/contract/Test-PipelinePlanStorage.ps1 -> module root).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
Import-Module powershell-yaml -ErrorAction Stop

$ciPath = Join-Path $RepoRoot 'workflows/terraform/templates/workflows/ci-template.yaml'
$cdPath = Join-Path $RepoRoot 'workflows/terraform/templates/workflows/cd-template.yaml'

foreach ($p in @($ciPath, $cdPath)) {
    if (-not (Test-Path -Path $p)) {
        throw "Template not found: $p"
    }
}

$ciRaw = Get-Content -Raw -Path $ciPath
$cdRaw = Get-Content -Raw -Path $cdPath
$ci = ConvertFrom-Yaml $ciRaw
$cd = ConvertFrom-Yaml $cdRaw

$script:failures = [System.Collections.Generic.List[string]]::new()
$script:passCount = 0

function Assert-Contract {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Description
    )
    if ($Condition) {
        Write-Host "  [PASS] $Description" -ForegroundColor Green
        $script:passCount++
    }
    else {
        Write-Host "  [FAIL] $Description" -ForegroundColor Red
        $script:failures.Add($Description)
    }
}

function Get-StepByName {
    param(
        [Parameter(Mandatory)]$Job,
        [Parameter(Mandatory)][string]$Name
    )
    return $Job['steps'] | Where-Object { $_['name'] -eq $Name }
}

Write-Host "=== Secure plan storage contract tests (issue #4174) ===" -ForegroundColor Cyan

# --- Locate the steps under test ---
$ciPlanJob = $ci['jobs']['plan']
$cdPlanJob = $cd['jobs']['plan']
$cdApplyJob = $cd['jobs']['apply']

$ciCleanup = Get-StepByName -Job $ciPlanJob -Name 'Clean Up Plan Working Directory'
$cdPlanCleanup = Get-StepByName -Job $cdPlanJob -Name 'Clean Up Plan Working Directory'
$cdApplyCleanup = Get-StepByName -Job $cdApplyJob -Name 'Clean Up Plan Working Directory'
$uploadStep = Get-StepByName -Job $cdPlanJob -Name 'Upload Plan to Storage'
$downloadStep = Get-StepByName -Job $cdApplyJob -Name 'Download Plan from Storage'
$deleteStep = Get-StepByName -Job $cdApplyJob -Name 'Delete Applied Plan from Storage'
$artifactStep = Get-StepByName -Job $cdPlanJob -Name 'Create Module Artifact'
$publishStep = Get-StepByName -Job $cdPlanJob -Name 'Publish Module Artifact'
$ciPreparePlanDir = Get-StepByName -Job $ciPlanJob -Name 'Prepare Plan Working Directory'
$cdPlanPrepareDir = Get-StepByName -Job $cdPlanJob -Name 'Prepare Plan Working Directory'
$cdApplyPrepareDir = Get-StepByName -Job $cdApplyJob -Name 'Prepare Plan Working Directory'

foreach ($pair in @(
        @{ Name = 'Upload Plan to Storage'; Step = $uploadStep },
        @{ Name = 'Download Plan from Storage'; Step = $downloadStep },
        @{ Name = 'Delete Applied Plan from Storage'; Step = $deleteStep },
        @{ Name = 'Create Module Artifact'; Step = $artifactStep },
        @{ Name = 'Publish Module Artifact'; Step = $publishStep }
    )) {
    if (-not $pair.Step) {
        throw "Expected step '$($pair.Name)' was not found in cd-template.yaml. Contract test cannot proceed - has the step been renamed?"
    }
}

# --- 1. Same computed container + execution-bound key across upload/download/delete ---
Write-Host "`n-- Consistent, execution-bound blob addressing --"
$blobNamePattern = '\$blobName\s*=\s*"runs/\$\{\{\s*github\.run_id\s*\}\}/tfplan"'
$containerPattern = '\$container\s*=\s*"\$\{\{\s*vars\.PLAN_STORAGE_CONTAINER_NAME\s*\}\}"'
foreach ($pair in @(
        @{ Name = 'upload'; Step = $uploadStep },
        @{ Name = 'download'; Step = $downloadStep },
        @{ Name = 'delete'; Step = $deleteStep }
    )) {
    Assert-Contract -Condition ($pair.Step['run'] -match $blobNamePattern) `
        -Description "The $($pair.Name) step keys the blob as 'runs/<run_id>/tfplan' (execution-bound, not attempt-bound)."
    Assert-Contract -Condition ($pair.Step['run'] -match $containerPattern) `
        -Description "The $($pair.Name) step reads the container name from vars.PLAN_STORAGE_CONTAINER_NAME."
    Assert-Contract -Condition ($pair.Step['run'] -notmatch 'run_attempt') `
        -Description "The $($pair.Name) step's blob key does not embed github.run_attempt."
}

# --- 2. runner.temp paths only ---
Write-Host "`n-- Working directories use RUNNER_TEMP only --"
foreach ($pair in @(
        @{ Name = 'ci plan job'; Step = $ciPreparePlanDir },
        @{ Name = 'cd plan job'; Step = $cdPlanPrepareDir },
        @{ Name = 'cd apply job'; Step = $cdApplyPrepareDir }
    )) {
    Assert-Contract -Condition ($pair.Step['run'] -match '\$env:RUNNER_TEMP') `
        -Description "The $($pair.Name) prepares its working directory under `$env:RUNNER_TEMP."
    Assert-Contract -Condition ($pair.Step['run'] -notmatch '\$env:TEMP\b' -and $pair.Step['run'] -notmatch '[A-Za-z]:\\\\(?!.*RUNNER_TEMP)') `
        -Description "The $($pair.Name) does not fall back to a non-RUNNER_TEMP or hardcoded path."
}

# --- 3 & 4. Plan excluded from secure artifact staging; legacy fallback copies it explicitly ---
Write-Host "`n-- Plan file staging matches the USE_STORAGE_ACCOUNT_FOR_PLAN flag --"
$artifactRun = $artifactStep['run']
Assert-Contract -Condition ($artifactRun -match [regex]::Escape('if ("${{ vars.USE_STORAGE_ACCOUNT_FOR_PLAN }}" -ne ''true'') {')) `
    -Description "Copying tfplan into the build artifact staging directory is guarded by 'USE_STORAGE_ACCOUNT_FOR_PLAN -ne true'."
Assert-Contract -Condition ($artifactRun -match 'Copy-Item\s+-Path\s+\$planFile\s+-Destination\s+"\./\$stagingDirectory/tfplan"') `
    -Description "The legacy (non-storage-account) fallback explicitly copies tfplan into the staging directory."
Assert-Contract -Condition ($publishStep['with']['path'] -eq './staging/') `
    -Description "The published build artifact only ever contains the staging directory (never the RUNNER_TEMP plan directory)."

# --- 5. always() cleanup ---
Write-Host "`n-- Working directory cleanup always runs --"
foreach ($pair in @(
        @{ Name = 'ci plan job'; Step = $ciCleanup },
        @{ Name = 'cd plan job'; Step = $cdPlanCleanup },
        @{ Name = 'cd apply job'; Step = $cdApplyCleanup }
    )) {
    Assert-Contract -Condition ($null -ne $pair.Step -and "$($pair.Step['if'])".Trim() -eq 'always()') `
        -Description "The $($pair.Name) cleanup step runs unconditionally (if: always())."
}

# --- 6. Exact 'true' string comparisons for both feature flags ---
Write-Host "`n-- Feature flags are compared as exact 'true' strings --"
$flagNames = @('USE_STORAGE_ACCOUNT_FOR_PLAN', 'SHOW_PLAN_IN_PIPELINE_LOGS')
foreach ($fileInfo in @(
        @{ Name = 'ci-template.yaml'; Raw = $ciRaw },
        @{ Name = 'cd-template.yaml'; Raw = $cdRaw }
    )) {
    foreach ($flag in $flagNames) {
        $comparisonLines = ($fileInfo.Raw -split "`n") | Where-Object { $_ -match [regex]::Escape($flag) -and $_ -match '(==|-eq|-ne)' }
        foreach ($line in $comparisonLines) {
            Assert-Contract -Condition ($line -match "(==|-eq|-ne)\s*'true'") `
                -Description "$($fileInfo.Name): comparison against $flag uses a quoted 'true' string ($($line.Trim()))."
        }
    }
}

# --- 8. No blob listing, no "latest" convention, no shared-key auth ---
Write-Host "`n-- No blob listing, no latest-blob convention, no shared-key auth --"
Assert-Contract -Condition ($ciRaw -notmatch 'az storage blob list' -and $cdRaw -notmatch 'az storage blob list') `
    -Description "Neither template lists blobs (downloads/deletes address an exact known key only)."
Assert-Contract -Condition ($ciRaw -notmatch '--account-key' -and $cdRaw -notmatch '--account-key') `
    -Description "Neither template authenticates with a storage account shared key."
foreach ($pair in @(
        @{ Name = 'upload'; Step = $uploadStep },
        @{ Name = 'download'; Step = $downloadStep },
        @{ Name = 'delete'; Step = $deleteStep }
    )) {
    Assert-Contract -Condition ($pair.Step['run'] -notmatch '(?i)\blatest\b') `
        -Description "The $($pair.Name) step does not use a mutable 'latest' blob alias."
}

# --- 9. --auth-mode login + content validation + bounded retries ---
Write-Host "`n-- Auth mode, content validation, bounded retries --"
foreach ($pair in @(
        @{ Name = 'upload'; Step = $uploadStep; Command = 'az storage blob upload' },
        @{ Name = 'download'; Step = $downloadStep; Command = 'az storage blob download' },
        @{ Name = 'delete'; Step = $deleteStep; Command = 'az storage blob delete' }
    )) {
    $run = $pair.Step['run']
    Assert-Contract -Condition ($run -match [regex]::Escape($pair.Command)) `
        -Description "The $($pair.Name) step calls '$($pair.Command)'."
    Assert-Contract -Condition ($run -match '--auth-mode login') `
        -Description "The $($pair.Name) step authenticates with --auth-mode login (Microsoft Entra ID, not a shared key)."
    Assert-Contract -Condition ($run -match '\$maxAttempts\s*=\s*\d+' -and $run -match 'for\s*\(\$attempt\s*=\s*1;\s*\$attempt\s*-le\s*\$maxAttempts') `
        -Description "The $($pair.Name) step retries a bounded number of times (not an unbounded loop)."
}
Assert-Contract -Condition ($uploadStep['run'] -match 'az storage blob show' -and $uploadStep['run'] -match '--query properties\.contentLength') `
    -Description "The upload step verifies the uploaded blob's content length against the local plan file."
Assert-Contract -Condition ($downloadStep['run'] -match '\(Get-Item\s+-Path\s+\$planFile\)\.Length\s+-eq\s+0') `
    -Description "The download step rejects an empty downloaded plan file."

# --- 10. No plan JSON artifact ---
Write-Host "`n-- No plan JSON ships in the build artifact --"
Assert-Contract -Condition ($artifactRun -notmatch 'tfplan\.json') `
    -Description "Create Module Artifact never references tfplan.json."
$ciPlanSummary = Get-StepByName -Job $ciPlanJob -Name 'Terraform Plan Summary'
Assert-Contract -Condition ($null -eq $ciPlanSummary -or $ciPlanSummary['run'] -match [regex]::Escape('steps.plan_paths.outputs.plan_dir')) `
    -Description "Where tfplan.json is generated (CI plan summary), it is written under the RUNNER_TEMP plan directory, never under the artifact staging directory."

# --- 11. Fail-closed upload/download, fail-open post-success delete ---
Write-Host "`n-- Fail-closed upload/download; fail-open (warn-only) cleanup delete --"
Assert-Contract -Condition ($uploadStep['run'] -match 'if\s*\(-not\s*\$uploaded\)\s*\{\s*\r?\n\s*throw') `
    -Description "Upload failure throws (fails the pipeline closed) rather than silently continuing."
Assert-Contract -Condition ($downloadStep['run'] -match 'if\s*\(-not\s*\$downloaded\)\s*\{\s*\r?\n\s*throw') `
    -Description "Download failure throws (fails the pipeline closed) rather than silently continuing."
Assert-Contract -Condition ($downloadStep['run'] -match 'Test-Path[^\r\n]*\$planFile\)[\s\S]{0,40}-or[\s\S]{0,80}-eq 0\)\s*\{\s*\r?\n\s*throw') `
    -Description "A missing or empty downloaded plan file throws (fails the pipeline closed)."
Assert-Contract -Condition ($deleteStep['run'] -match 'if\s*\(-not\s*\$deleted\)\s*\{\s*\r?\n\s*Write-Warning') `
    -Description "Post-apply delete failure only warns (a completed apply is not marked failed just because blob cleanup could not run)."
Assert-Contract -Condition ("$($deleteStep['if'])" -match 'success\(\)') `
    -Description "The delete step only runs after a successful apply (never deletes the plan after a failed apply)."

# --- 12. Failed-plan output is redacted unless explicitly enabled ---
Write-Host "`n-- Failed-plan log output respects SHOW_PLAN_IN_PIPELINE_LOGS --"
foreach ($fileInfo in @(
        @{ Name = 'ci-template.yaml'; Raw = $ciRaw },
        @{ Name = 'cd-template.yaml'; Raw = $cdRaw }
    )) {
    $failureBlockMatch = [regex]::Match($fileInfo.Raw, '(?s)if\s*\(\$planExitCode\s*-ne\s*0\)\s*\{.*?throw\s*"Terraform plan failed with exit code \$planExitCode\."')
    Assert-Contract -Condition $failureBlockMatch.Success `
        -Description "$($fileInfo.Name): the failed-plan branch was found for inspection."
    if ($failureBlockMatch.Success) {
        $parts = $failureBlockMatch.Value -split '\}\s*else\s*\{', 2
        Assert-Contract -Condition ($parts.Count -eq 2) `
            -Description "$($fileInfo.Name): the failed-plan branch checks SHOW_PLAN_IN_PIPELINE_LOGS and has two paths."
        if ($parts.Count -eq 2) {
            $shownBranch = $parts[0]
            $redactedBranch = $parts[1]
            Assert-Contract -Condition ($shownBranch -match 'Get-Content -Path \$planLogFile \| Write-Host') `
                -Description "$($fileInfo.Name): the full captured plan log is only ever dumped inside the SHOW_PLAN_IN_PIPELINE_LOGS branch."
            Assert-Contract -Condition ($redactedBranch -match 'diagnosticBlocks') `
                -Description "$($fileInfo.Name): when the flag is not true, only Terraform's own diagnostic block(s) are extracted from the log."
            Assert-Contract -Condition ($redactedBranch -notmatch 'Get-Content -Path \$planLogFile \| Write-Host') `
                -Description "$($fileInfo.Name): the redacted branch never falls back to dumping the entire raw captured log."
        }
    }
}

# --- Summary ---
Write-Host "`n=== Summary: $($script:passCount) passed, $($script:failures.Count) failed ===" -ForegroundColor Cyan
if ($script:failures.Count -gt 0) {
    Write-Host "`nFailed checks:" -ForegroundColor Red
    foreach ($f in $script:failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
    exit 1
}
exit 0