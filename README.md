# privacy-hygiene

[![ci](https://github.com/jaschadub/devprivacy-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/jaschadub/devprivacy-skill/actions/workflows/ci.yml)

A Claude skill to opt out of telemetry and protect digital privacy across a development environment.

Two modes plus standing behaviors:

- **Opt-out** — apply telemetry kill switches (env vars + per-tool config) across detected tools. Idempotent and mostly reversible.
- **Audit** — read-only review of privacy posture: telemetry without opt-outs, key/file permissions, probable secrets in history and dotfiles, git identity leakage, tracked `.env` files, `curl | bash` rc lines, metadata tooling.
- **Active hygiene** — strip metadata before files leave the machine, flag phone-home dependencies, never scaffold analytics, redact shared output.

See [SKILL.md](SKILL.md) for the full behavior contract.

## Layout

```
SKILL.md                          skill definition + standing behaviors
scripts/optout.sh                 --detect / --apply / --verify / --undo
scripts/audit.sh                  read-only privacy audit
references/telemetry-optouts.md   catalog of env vars and config commands
```

## Install

Skills live under `~/.claude/skills/<name>/`, with `SKILL.md` at the root of that directory. Pick one:

**From the release bundle** (one download, no clone):

```sh
cd ~/.claude/skills
curl -L https://github.com/jaschadub/devprivacy-skill/releases/latest/download/privacy-hygiene.skill -o privacy-hygiene.zip
unzip privacy-hygiene.zip -d privacy-hygiene && rm privacy-hygiene.zip
```

**From a clone** (to track updates / hack on it):

```sh
git clone https://github.com/jaschadub/devprivacy-skill.git ~/.claude/skills/privacy-hygiene
```

**Build your own bundle** from a checkout:

```sh
zip -r privacy-hygiene.skill SKILL.md scripts references
```

Verify the layout — `~/.claude/skills/privacy-hygiene/SKILL.md` must exist. Claude picks the skill up on the next session.

## Usage

```sh
scripts/optout.sh --detect    # what's installed
scripts/optout.sh --apply     # apply opt-outs
scripts/optout.sh --verify    # confirm env vars resolve
scripts/optout.sh --undo      # revert the env-var layer
scripts/audit.sh              # read-only posture report
```

## License

MIT — see [LICENSE](LICENSE).
