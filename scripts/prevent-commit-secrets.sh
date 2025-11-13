#!/usr/bin/env bash
# scripts/prevent-commit-secrets.sh
# Exit non-zero if attempting to commit a file matching patterns.

set -euo pipefail

# patterns to block (add more as needed)
BLOCK_PATTERNS=('^\.env$' '^.*\.pem$' '^.*\.key$' '^credentials\.json$')

# Get staged files
STAGED=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED" ]; then
  exit 0
fi

for f in $STAGED; do
  for p in "${BLOCK_PATTERNS[@]}"; do
    if [[ "$f" =~ $p ]]; then
      echo "ERROR: Attempting to commit blocked file: $f"
      echo "Please remove secrets from this file, move it to .env, or add it to .gitignore"
      exit 1
    fi
  done
done

exit 0
