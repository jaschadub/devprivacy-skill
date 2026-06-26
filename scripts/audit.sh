#!/usr/bin/env bash
# privacy-hygiene audit.sh -- read-only privacy posture audit. Modifies nothing.
set -uo pipefail

# Repo-scan depth from $HOME, overridable: PRIVACY_HYGIENE_SCAN_DEPTH=6 audit.sh
SCAN_DEPTH="${PRIVACY_HYGIENE_SCAN_DEPTH:-4}"
OPTOUT_FILE="${HOME}/.config/privacy-hygiene/telemetry-optout.sh"

section() { echo; echo "== $1 =="; }

# Resolve an env var the way the user's actual login shell would, sourcing the
# rc that wires the opt-out. Falls back to bash if $SHELL is unknown.
shell_get() {
  local var="$1" sh="${SHELL:-/bin/bash}"
  case "$sh" in
    *zsh) command -v zsh  >/dev/null 2>&1 && zsh  -ic "echo \${$var:-UNSET}" 2>/dev/null | tail -n1 && return ;;
  esac
  bash -ic "echo \${$var:-UNSET}" 2>/dev/null | tail -n1
}

section "Telemetry opt-out status"
if [[ -f "$OPTOUT_FILE" ]]; then
  echo "  opt-out file present"
else
  echo "  [MED] no opt-out file; run optout.sh --apply"
fi
for var in DO_NOT_TRACK DOTNET_CLI_TELEMETRY_OPTOUT HOMEBREW_NO_ANALYTICS CHECKPOINT_DISABLE; do
  v="$(shell_get "$var")"
  [[ "$v" == "UNSET" || -z "$v" ]] && echo "  [LOW] $var not set in your login shell (${SHELL:-bash})"
done

section "SSH permissions"
if [[ -d "${HOME}/.ssh" ]]; then
  find "${HOME}/.ssh" -type f \( -perm -o+r -o -perm -g+r \) 2>/dev/null | while read -r f; do
    if [[ "$f" != *.pub && "$f" != *known_hosts* ]]; then
      echo "  [HIGH] group/world-readable: $f ($(stat -c '%a' "$f" 2>/dev/null || stat -f '%Lp' "$f"))"
    fi
  done
  dirperm="$(stat -c '%a' "${HOME}/.ssh" 2>/dev/null || stat -f '%Lp' "${HOME}/.ssh")"
  [[ "$dirperm" != "700" ]] && echo "  [MED] ~/.ssh is $dirperm, expected 700"
  echo "  (scan complete)"
else
  echo "  no ~/.ssh directory"
fi

section "Secrets in history, dotfiles, and credential stores"
# Single file set, used by both the gitleaks and the grep-fallback paths so
# installing gitleaks never reduces coverage.
SECRET_FILES=(
  "${HOME}/.bash_history" "${HOME}/.zsh_history" "${HOME}/.local/share/fish/fish_history"
  "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile" "${HOME}/.bash_profile" "${HOME}/.zprofile"
  "${HOME}/.netrc" "${HOME}/.npmrc" "${HOME}/.pypirc"
  "${HOME}/.aws/credentials" "${HOME}/.git-credentials"
  "${HOME}/.config/gh/hosts.yml" "${HOME}/.docker/config.json"
  "${HOME}/.config/gcloud/application_default_credentials.json"
)
if command -v gitleaks >/dev/null 2>&1; then
  echo "  gitleaks available; scanning files..."
  for f in "${SECRET_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    out="$(gitleaks detect --no-git --source "$f" --no-banner 2>/dev/null)"
    [[ -n "$out" ]] && echo "  [HIGH] gitleaks finding(s) in $f -- review and ROTATE, do not just delete"
  done
  echo "  (gitleaks scan complete)"
else
  echo "  gitleaks not installed; pattern grep (noisier)"
  PATTERNS='(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9-]{20,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{20,}\.eyJ)'
  for f in "${SECRET_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    hits="$(grep -cE "$PATTERNS" "$f" 2>/dev/null || true)"
    [[ "${hits:-0}" -gt 0 ]] && echo "  [HIGH] $hits token-shaped string(s) in $f -- review and ROTATE, do not just delete"
  done
  echo "  (pattern scan complete; install gitleaks for better coverage)"
fi
[[ -f "${HOME}/.netrc" ]] && echo "  [MED] ~/.netrc exists (plaintext creds by design); confirm needed and chmod 600"
[[ -f "${HOME}/.git-credentials" ]] && echo "  [MED] ~/.git-credentials exists (plaintext git creds); prefer a credential helper"
[[ -f "${HOME}/.aws/credentials" ]] && echo "  [INFO] ~/.aws/credentials present; prefer SSO/short-lived creds where possible"

section "Git identity"
global_email="$(git config --global user.email 2>/dev/null || echo none)"
echo "  global user.email: $global_email"
echo "  repos overriding it (first 10):"
find "${HOME}" -maxdepth "$SCAN_DEPTH" -name ".git" -type d 2>/dev/null | head -50 | while read -r g; do
  repo="${g%/.git}"
  local_email="$(git -C "$repo" config --local user.email 2>/dev/null || true)"
  [[ -n "$local_email" && "$local_email" != "$global_email" ]] && echo "    $repo -> $local_email"
done | head -10
echo "  (review for personal/client identity crossover; depth $SCAN_DEPTH)"

section "Tracked .env files in git repos"
find "${HOME}" -maxdepth "$SCAN_DEPTH" -name ".git" -type d 2>/dev/null | head -50 | while read -r g; do
  repo="${g%/.git}"
  tracked="$(git -C "$repo" ls-files 2>/dev/null | grep -E '(^|/)\.env(\..+)?$' | grep -v '\.example$' || true)"
  [[ -n "$tracked" ]] && echo "  [HIGH] $repo tracks: $(echo "$tracked" | tr '\n' ' ')"
done
echo "  (scan complete, depth $SCAN_DEPTH from \$HOME)"

section "curl|bash patterns in shell rc"
for f in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile" "${HOME}/.bash_profile" "${HOME}/.zprofile"; do
  [[ -f "$f" ]] || continue
  grep -nE '(curl|wget)[^|]*\|\s*(ba)?sh' "$f" 2>/dev/null | while read -r line; do
    echo "  [MED] $f: $line"
  done
done
echo "  (scan complete)"

section "Metadata tooling"
command -v exiftool >/dev/null 2>&1 && echo "  exiftool: present" || echo "  [LOW] exiftool missing (image/PDF metadata stripping)"
command -v mat2 >/dev/null 2>&1 && echo "  mat2: present" || echo "  [LOW] mat2 missing (broad-spectrum metadata removal)"

echo
echo "Audit complete. Read-only; nothing was modified."
