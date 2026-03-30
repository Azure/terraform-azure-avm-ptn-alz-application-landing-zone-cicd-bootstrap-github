# Pre-test script to set authentication environment variables from secrets
# This script is run before terraform init/plan/apply in the test pipeline

# Set the GitHub token from the repository secret for provider auth
# The GITHUB_TOKEN env var is used by the github provider
$env:GITHUB_TOKEN = $env:GITHUB_TOKEN

# For module auth, the personal_access_token variable can be set via:
# $env:TF_VAR_personal_access_token = $env:GITHUB_TOKEN
# This is only needed when runner_authentication_method is "pat"
