# privacy-hygiene

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

Drop this directory into your Claude skills path (e.g. `~/.claude/skills/privacy-hygiene/`), or package it:

```sh
zip -r privacy-hygiene.skill SKILL.md scripts references
```

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
