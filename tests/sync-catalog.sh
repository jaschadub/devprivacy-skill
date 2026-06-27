#!/usr/bin/env bash
# Fail if optout.sh's arrays drift from references/telemetry-optouts.md.
# Guards the "KEEP IN SYNC" comments that are otherwise enforced by hand.
# ponytail: env vars matched bidirectionally; per-tool commands matched by the
# first backtick span per table row. If the catalog format gets fancier than
# that, upgrade to a real markdown parser.
set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT=scripts/optout.sh
CAT=references/telemetry-optouts.md
fail=0

cmp_sets() { # label, scriptset, catalogset
  if ! diff <(echo "$2") <(echo "$3") >/dev/null; then
    echo "DRIFT: $1 differ between $SCRIPT and $CAT"
    echo "  (< only in script, > only in catalog)"
    diff <(echo "$2") <(echo "$3") | grep -E '^[<>]' | sed 's/^/  /'
    fail=1
  fi
}

# Env vars: uppercase NAME=value tokens. In the script, only inside ENV_VARS=();
# in the catalog, anywhere (every documented var should be set, and vice versa).
script_env=$(awk '/^ENV_VARS=\(/{f=1;next} f&&/^\)/{f=0} f' "$SCRIPT" \
  | grep -oE '[A-Z][A-Z0-9_]+=[A-Za-z0-9]+' | sort -u)
catalog_env=$(grep -oE '[A-Z][A-Z0-9_]+=[A-Za-z0-9]+' "$CAT" | sort -u)
cmp_sets "env vars" "$script_env" "$catalog_env"

# Per-tool commands: field 2 of each TOOL_COMMANDS entry vs the first backtick
# span of each row in the catalog's "Per-tool commands" table.
script_cmd=$(awk '/^TOOL_COMMANDS=\(/{f=1;next} f&&/^\)/{f=0} f' "$SCRIPT" \
  | grep -oE '"[^"]+"' | tr -d '"' | awk -F'|' '{print $2}' | sort -u)
# shellcheck disable=SC2016  # backticks are sed syntax, not command substitution
catalog_cmd=$(awk '/^## Per-tool commands/{f=1;next} f&&/^## /{f=0} f' "$CAT" \
  | grep -E '^\|' | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p' | sort -u)
cmp_sets "per-tool commands" "$script_cmd" "$catalog_cmd"

[[ $fail -eq 0 ]] && echo "catalog in sync with optout.sh"
exit $fail
