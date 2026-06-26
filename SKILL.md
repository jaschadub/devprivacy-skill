---
name: privacy-hygiene
description: Opt out of telemetry and protect digital privacy across the development environment. Use this skill whenever the user mentions telemetry, tracking, analytics opt-out, phone-home behavior, privacy audit, digital hygiene, metadata stripping, secret leakage in dotfiles or shell history, or asks to "lock down" or "harden" their workstation. Also trigger proactively when installing new CLI tools or frameworks known to ship telemetry (Next.js, .NET, Homebrew, HashiCorp tools, Azure CLI, etc.), when the user is about to share files externally (strip metadata first), or when reviewing a project's dependencies for tracking SDKs.
---

# Privacy Hygiene

A skill with two modes: **opt-out** (apply telemetry kill switches across the dev environment) and **audit** (read-only review of privacy posture). It also defines standing behaviors Claude should follow in any session where this skill is active.

## Design principles

1. **Idempotent and mostly reversible.** All env var opt-outs live in one generated file (`~/.config/privacy-hygiene/telemetry-optout.sh`) sourced from the shell rc files; re-running `--apply` regenerates it in place. `optout.sh --undo` removes that file and strips the guarded source lines from every rc, cleanly reverting the env-var layer. Per-tool config commands (`brew analytics off`, etc.) and the VS Code recommendation write to each tool's own config and are **not** auto-reverted; `--undo` lists them so the user can reverse them by hand. Never scatter exports across rc files.
2. **Read-only by default, no destructive edits.** The audit never modifies anything. The opt-out script writes only to its own config file, the shell rc files (one guarded source line each), and per-tool config stores. It never rewrites a file it did not create: VS Code telemetry is reported, not edited, so existing settings.json comments and formatting are preserved.
3. **Report before acting.** Show the user what will change and which tools were detected before applying.
4. **No silent network calls.** This skill never phones out to verify anything. Verification is local (env checks, config file reads).

## Mode 1: Telemetry opt-out

When the user asks to opt out of telemetry or disable tracking:

1. Read `references/telemetry-optouts.md` for the full catalog of env vars and config commands.
2. Run `scripts/optout.sh --detect` to see which telemetry-bearing tools are installed.
3. Show the user the detection report and the proposed changes.
4. On approval, run `scripts/optout.sh --apply`. This:
   - Writes all env var opt-outs to `~/.config/privacy-hygiene/telemetry-optout.sh`
   - Adds a guarded source line to each existing shell rc, login and interactive (`.bashrc`, `.bash_profile`, `.zshrc`, `.zprofile`, `.profile`), so macOS login shells pick it up too. It never creates an rc that does not already exist.
   - Runs per-tool config commands for detected tools (`brew analytics off`, etc.), tagging failures from **(verify)** mechanisms distinctly
   - Reports VS Code/VSCodium telemetry state (advisory only; does not edit settings.json)
5. Run `scripts/optout.sh --verify` to confirm the env vars resolve. Verify tests the user's actual login shell (bash or zsh, whichever rc was wired), and falls back to sourcing the opt-out file directly if that shell binary is absent.
6. To revert, run `scripts/optout.sh --undo` (removes the env-var layer; lists per-tool reversals).

Entries in the catalog marked **(verify)** have opt-out mechanisms that change between tool versions. Check current docs before relying on them, and tell the user which ones you could not verify locally.

## Mode 2: Privacy audit

When the user asks for a privacy or hygiene audit, run `scripts/audit.sh`. It is read-only and reports:

- Telemetry-bearing tools installed without active opt-outs
- SSH key and config file permissions (anything group/world readable)
- Probable secrets in shell history, dotfiles, and credential stores (`.aws/credentials`, `.git-credentials`, `.npmrc`, `.pypirc`, `.netrc`, `gh hosts.yml`, Docker/gcloud creds; token-shaped strings; uses gitleaks if installed, falls back to grep patterns). The gitleaks and grep paths scan the same file set, so installing gitleaks never narrows coverage.
- Git identity leakage: `user.email` set to a personal address in repos that look like client work, and vice versa (repo scan depth is `PRIVACY_HYGIENE_SCAN_DEPTH`, default 4)
- `.env` files tracked in git working trees under the home directory
- Shell rc lines that pipe remote content to a shell (`curl | bash` patterns)
- Presence/absence of metadata-stripping tooling (exiftool, mat2)

Present findings ordered by severity. For each finding, give the one-line remediation. Do not auto-remediate; secrets in history especially need human judgment (rotating the credential matters more than scrubbing the file).

## Standing behaviors (active hygiene)

While this skill is in play, follow these rules without being asked:

- **Before any file leaves the machine** (email attachment, upload, shared deliverable): check for and strip metadata. Images/PDFs/Office docs carry author names, GPS, hostnames, revision history. Use exiftool or the relevant library; tell the user what was removed.
- **When adding dependencies**: flag packages whose install or runtime phones home (Scarf-instrumented npm packages, SDKs with default analytics, postinstall scripts that hit the network). Suggest the opt-out or an alternative.
- **When writing code**: never add analytics, crash reporting, or update checks by default. If a framework scaffold enables telemetry (create-next-app, dotnet new), disable it in the generated project.
- **When showing terminal output or logs to be shared**: redact tokens, internal hostnames, IPs, and usernames before they go into a report or ticket.
- **When the user installs a new tool from the catalog**: mention its telemetry and offer the opt-out in the same breath.

## What this skill does not do

- Browser hardening, DNS, VPN, or OS-level MDM/telemetry (macOS/Windows) — out of scope for now; say so if asked and handle ad hoc.
- Anything requiring sudo. Flag system-level findings; let the user act on them.
