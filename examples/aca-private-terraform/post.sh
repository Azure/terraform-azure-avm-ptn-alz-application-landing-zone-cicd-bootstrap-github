#!/usr/bin/env bash
# Remove the .env file written by pre.sh so the token is not left behind.
set -euo pipefail

rm -f .env