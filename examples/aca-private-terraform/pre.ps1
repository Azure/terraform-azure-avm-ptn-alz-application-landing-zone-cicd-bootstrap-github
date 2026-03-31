# Pre-test script to set authentication environment variables from secrets
# This script is run before terraform init/plan/apply in the test pipeline

# Set the GitHub token from the repository secret for provider auth
# The GITHUB_TOKEN env var is used by the github provider
$env:GITHUB_TOKEN = $env:TF_VAR_github_token

# Set the GitHub owner/org for provider auth
# Derived from TF_VAR_github_organization_name which is the single source of truth
$env:GITHUB_OWNER = $env:TF_VAR_github_organization_name
