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
TMP_JSON=$(mktemp)
$DETECT_SECRETS_CMD scan --json $STAGED > "$TMP_JSON" || true

# If no existing baseline, fail to be safe
if [ ! -f .secrets.baseline ]; then
  echo ".secrets.baseline not found. Please generate one with 'detect-secrets scan > .secrets.baseline' and audit it." >&2
  rm -f "$TMP_JSON"
  exit 1
fi

# Use Python to compare hashed_secret entries between baseline and new scan.
python3 - <<PY
import json,sys
def load_hashes(path):
  with open(path,'r') as f:
    data=json.load(f)
  results=data.get('results',{})
  hashes=set()
  for fname, items in results.items():
    for it in items:
      if 'hashed_secret' in it:
        hashes.add(it['hashed_secret'])
  return hashes,results

base_hashes, base_results = load_hashes('.secrets.baseline')
new_hashes, new_results = load_hashes('$TMP_JSON')
new_only = new_hashes - base_hashes
if new_only:
  print('Potential new secrets detected in staged files. New hashed secrets:')
  for h in new_only:
    # find occurrences
    for fname, items in new_results.items():
      for it in items:
        if it.get('hashed_secret')==h:
          print(f"- {fname}: {it.get('type')} (line {it.get('line_number')})")
  sys.exit(1)
sys.exit(0)
PY

rc=$?
rm -f "$TMP_JSON"
exit $rc
