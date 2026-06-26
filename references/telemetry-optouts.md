# Telemetry opt-out catalog

Single source of truth for the optout script. The script's `ENV_VARS` and `TOOL_COMMANDS` arrays must match the tables below; both carry a "KEEP IN SYNC" comment. Entries marked **(verify)** have mechanisms known to drift between versions; check current docs before relying on them.

## Universal convention

| Var | Effect |
|---|---|
| `DO_NOT_TRACK=1` | consoledonottrack.com convention. Respected by Bun, Mailpit, and a growing set of CLIs. Cheap insurance; always set. |

## Environment variables (set unconditionally; harmless if tool absent)

| Tool | Variable |
|---|---|
| .NET CLI | `DOTNET_CLI_TELEMETRY_OPTOUT=1` |
| PowerShell | `POWERSHELL_TELEMETRY_OPTOUT=1` |
| Next.js | `NEXT_TELEMETRY_DISABLED=1` |
| Nuxt | `NUXT_TELEMETRY_DISABLED=1` |
| Gatsby | `GATSBY_TELEMETRY_DISABLED=1` |
| Astro | `ASTRO_TELEMETRY_DISABLED=1` |
| Storybook | `STORYBOOK_DISABLE_TELEMETRY=1` |
| Turborepo | `TURBO_TELEMETRY_DISABLED=1` |
| Expo | `EXPO_NO_TELEMETRY=1` |
| Gemini CLI | `GEMINI_TELEMETRY_ENABLED=false` |
| Angular CLI | `NG_CLI_ANALYTICS=false` |
| Scarf (npm package analytics) | `SCARF_ANALYTICS=false` |
| Homebrew | `HOMEBREW_NO_ANALYTICS=1` |
| HashiCorp (Terraform, Packer, Vagrant, Consul update/usage checks) and Prisma | `CHECKPOINT_DISABLE=1` |
| Azure CLI | `AZURE_CORE_COLLECT_TELEMETRY=0` |
| AWS SAM CLI | `SAM_CLI_TELEMETRY=0` |
| Stripe CLI | `STRIPE_CLI_TELEMETRY_OPTOUT=1` |
| Cloudflare Wrangler | `WRANGLER_SEND_METRICS=false` |
| Salesforce CLI | `SF_DISABLE_TELEMETRY=true` and `SFDX_DISABLE_TELEMETRY=true` |
| Serverless Framework | `SLS_TELEMETRY_DISABLED=1` |
| Fastlane | `FASTLANE_OPT_OUT_USAGE=1` |
| Hasura | `HASURA_GRAPHQL_ENABLE_TELEMETRY=false` |
| Strapi | `STRAPI_TELEMETRY_DISABLED=true` |
| Meltano | `MELTANO_SEND_ANONYMOUS_USAGE_STATS=False` |
| InfluxDB | `INFLUXD_REPORTING_DISABLED=true` |
| Rasa | `RASA_TELEMETRY_ENABLED=false` |
| Earthly | `EARTHLY_DISABLE_ANALYTICS=true` |
| Pants | `PANTS_ANONYMOUS_TELEMETRY_ENABLED=false` |
| Semgrep | `SEMGREP_SEND_METRICS=off` |
| Grype | `GRYPE_CHECK_FOR_APP_UPDATE=false` |
| Syft | `SYFT_CHECK_FOR_APP_UPDATE=false` |
| Trivy (update check, not telemetry) | `TRIVY_SKIP_VERSION_CHECK=true` |
| Claude Code | `DISABLE_TELEMETRY=1`, `DISABLE_ERROR_REPORTING=1`, `DISABLE_FEEDBACK_COMMAND=1`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` |

## Per-tool commands (run only when tool detected)

| Tool | Command |
|---|---|
| Homebrew | `brew analytics off` (belt-and-suspenders with the env var) |
| Go toolchain (1.23+) | `go telemetry off` |
| Flutter | `flutter config --no-analytics` **(verify)** |
| Dart | `dart --disable-analytics` |
| Vercel CLI | `vercel telemetry disable` |
| Netlify CLI | `netlify --telemetry-disable` **(verify)** |
| Ionic | `ionic config set --global telemetry false` |
| Cordova | `cordova telemetry off` |
| DVC | `dvc config --global core.analytics false` |
| Yarn 2+ | `yarn config set --home enableTelemetry 0` |
| gcloud | `gcloud config set disable_usage_reporting true` |
| gh CLI | `gh config set telemetry disabled` **(verify)** (also honors `DO_NOT_TRACK`) |

## Config file edits

| Tool | Edit |
|---|---|
| VS Code / VSCodium | `settings.json`: `"telemetry.telemetryLevel": "off"`. The optout script only *reports* this (advisory); it does not rewrite settings.json, to avoid stripping comments and reformatting. Apply by hand. Also consider `"update.mode": "manual"`, `"extensions.autoCheckUpdates": false`. VSCodium ships with telemetry off. |
| JetBrains IDEs | Settings → Appearance & Behavior → Data Sharing (no clean env var) **(verify)** |

## Notes

- npm itself has no telemetry, but packages instrumented with Scarf do; `SCARF_ANALYTICS=false` covers them.
- pnpm and Deno currently ship no telemetry.
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` disables auto-update checks as well as telemetry. Drop it if you rely on Claude Code self-updating.
- gh CLI added opt-in telemetry recently; it honors `DO_NOT_TRACK` and `gh config set telemetry disabled`. The exact config key is newer, hence **(verify)**.
- Update checks (Trivy, Grype, Syft, gh) are not telemetry per se but do leak version + IP on every run; included because the user's threat model may care.
- macOS and Windows OS-level telemetry is intentionally out of scope (see SKILL.md).
