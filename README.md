# Claude Usage Bar

A tiny, beautiful **macOS menu-bar tracker** for your **Claude Max/Pro** usage — 5-hour session, weekly (all models), and weekly (scoped model) limits, live in your menu bar with color-coded themes.

```
◐ 5h 2% · wk 4% · Fab 8%
```

Click it for a full breakdown: per-limit progress bars, reset countdowns, and the active limit.

---

> [!IMPORTANT]
> **Unofficial. Not affiliated with, or endorsed by, Anthropic.**
> This reads **your own** usage using **your own** local Claude Code login token, by calling an **undocumented** endpoint (`/api/oauth/usage`) that Anthropic may change or remove at any time. It polls gently (every 5 min, with exponential backoff) to respect rate limits. Use at your own discretion. No data leaves your machine; there is no server, telemetry, or account beyond your existing Claude login.

---

## Features
- 🎯 Exact **session / weekly / scoped** percentages (same numbers as the claude.ai usage page)
- 🎨 **5 themes** — Ocean (default), Severity, Claude, Per-Metric, Minimal
- ⏱️ **Reset countdowns** per limit
- 🟢 Color-coded status (Healthy → Moderate → High → Critical)
- 🔁 **Launch at Login** toggle (modern `SMAppService`, no LaunchAgents)
- 🪶 Native Swift/AppKit, ~single file, no dependencies, no telemetry

## Requirements
- macOS 13+ (Ventura or later)
- An existing **Claude Code** login (run `claude` once and sign in). The app reads the token from your Keychain — it never asks for credentials.
- Xcode Command Line Tools (`xcode-select --install`) — only needed to build.

## Install

### Homebrew (builds from source — no Gatekeeper prompts)
```bash
brew install sagar-18/tap/claude-usage-bar
claude-usage-bar &          # start it
```
Then enable **Launch at Login** from the menu.

### Manual
```bash
git clone https://github.com/sagar-18/claude-usage-bar
cd claude-usage-bar
./build.sh
open ClaudeUsageBar.app
```

## Why does it need the `claude-code` User-Agent?
The `/api/oauth/usage` endpoint is [aggressively rate-limited](https://github.com/anthropics/claude-code/issues/31637) and returns persistent `429`s to clients that don't send a `User-Agent: claude-code/<version>` header. This app sends it so the endpoint responds normally. It still polls only every 5 minutes and backs off on errors.

## Privacy
- Reads the OAuth token from the macOS Keychain item `Claude Code-credentials` (created by Claude Code itself).
- Talks **only** to `api.anthropic.com`. Nothing is logged, stored remotely, or sent anywhere else.
- Fully open source — read [`Sources/ClaudeUsageBar.swift`](Sources/ClaudeUsageBar.swift).

## License
[MIT](LICENSE). "Claude" is a trademark of Anthropic; this project is not affiliated with Anthropic.
