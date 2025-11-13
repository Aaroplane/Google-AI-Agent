#!/usr/bin/env bash
# scripts/run-detect-secrets.sh
# Local pre-commit wrapper that runs detect-secrets against staged files.

set -euo pipefail

# prefer venv-installed detect-secrets if present
DETECT_SECRETS_CMD="detect-secrets"
if [ -x "./.venv/bin/detect-secrets" ]; then
  DETECT_SECRETS_CMD="./.venv/bin/detect-secrets"
fi

# if detect-secrets-hook exists, use it (it's the official pre-commit entrypoint)
if command -v detect-secrets-hook >/dev/null 2>&1; then
  detect-secrets-hook --baseline .secrets.baseline
  exit $?
fi

# Get staged files
STAGED=$(git diff --cached --name-only --diff-filter=ACM)
if [ -z "$STAGED" ]; then
  exit 0
fi

# Run detect-secrets scan on staged files and write to temp baseline
TMP_BASELINE=$(mktemp)
$DETECT_SECRETS_CMD scan $STAGED > "$TMP_BASELINE" || true

# If no existing baseline, fail to be safe
if [ ! -f .secrets.baseline ]; then
  echo ".secrets.baseline not found. Please generate one with 'detect-secrets scan > .secrets.baseline' and audit it." >&2
  rm -f "$TMP_BASELINE"
  exit 1
fi

# Compare baselines: if differences exist, new secrets may have been introduced
if ! diff -q .secrets.baseline "$TMP_BASELINE" >/dev/null 2>&1; then
  echo "Potential new secrets detected in staged files. Diff against baseline:" >&2
  diff .secrets.baseline "$TMP_BASELINE" || true
  rm -f "$TMP_BASELINE"
  exit 1
fi

rm -f "$TMP_BASELINE"
exit 0
