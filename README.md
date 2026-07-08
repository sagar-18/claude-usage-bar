# Claude Usage Bar

A tiny, beautiful **macOS menu-bar tracker** for your **Claude Max/Pro** usage — 5-hour session, weekly (all models), and weekly (scoped model) limits, live in your menu bar with color-coded themes.

```
◐ 5h 2% · wk 4% · Fab 8%
```

Click it for a full breakdown: per-limit progress bars, reset countdowns, and the active limit.

---

> [!IMPORTANT]
> **Unofficial. Not affiliated with, or endorsed by, Anthropic.**
> This reads **your own** usage using **your own** local Claude Code login token, by calling an **undocumented** endpoint (`/api/oauth/usage`) that Anthropic may change or remove at any time. It polls gently (every 5 min by default, with exponential backoff) to respect rate limits. No data leaves your machine; there is no server, telemetry, or account beyond your existing Claude login.

> [!WARNING]
> **Use at your own risk — no warranty, no liability.**
> This software is provided **"as is"**, without warranty of any kind. The author and contributors are **not responsible or liable** for anything that happens to your Claude / Anthropic account — including but not limited to rate limiting, throttling, suspension, or termination — arising from the use of this application or the undocumented endpoint it calls. It relies on an unofficial, undocumented API that can change or break without notice. **By installing or using it, you accept full responsibility.** If you are unsure, don't use it.

---

## Features
- 🎯 Exact **session / weekly / scoped** percentages (same numbers as the claude.ai usage page)
- 🎨 **5 themes** — Ocean (default), Severity, Claude, Per-Metric, Minimal
- 📏 **3 menu-bar styles** — Full (`◐ 5h 2% · wk 4% · Fab 8%`), Compact (`◐ 8%`, worst limit), or 5-hour session only (`◐ 5h 2%`) — the narrow styles fit crowded/notched menu bars
- ⏱️ **Reset countdowns** per limit
- 🟢 Color-coded status (Healthy → Moderate → High → Critical)
- 🔁 **Launch at Login** toggle (modern `SMAppService`, no LaunchAgents)
- ⬆️ **In-app updates** — checks GitHub releases daily; one click runs `brew reinstall` and relaunches (no Sparkle, no downloaded binaries)
- 🪶 Native Swift/AppKit, ~single file, no dependencies, no telemetry

## Requirements
- macOS 13+ (Ventura or later)
- An existing **Claude Code** login (run `claude` once and sign in). The app reads the token from your Keychain — it never asks for credentials.
- Xcode Command Line Tools (`xcode-select --install`) — only needed to build.

## Install

### Homebrew (builds from source — no Gatekeeper prompts, single repo)
```bash
brew tap sagar-18/claude-usage-bar https://github.com/sagar-18/claude-usage-bar
brew install --HEAD sagar-18/claude-usage-bar/claude-usage-bar
claude-usage-bar            # start it (launches detached; survives terminal close)
```
Everything lives in this one repo — the [formula](Formula/claude-usage-bar.rb) ships right here in `Formula/`, and `brew tap` points at this repo directly (no separate `homebrew-tap` repo). Then enable **Launch at Login** from the menu.

To update later: the app checks GitHub daily and shows **"Update to X.Y.Z available…"** in its menu — one click rebuilds via brew and relaunches. Or manually: `brew update && brew reinstall claude-usage-bar`.

### Manual
```bash
git clone https://github.com/sagar-18/claude-usage-bar
cd claude-usage-bar
./build.sh
open ClaudeUsageBar.app
```

## Privacy
- Reads the OAuth token from the macOS Keychain item `Claude Code-credentials` (created by Claude Code itself).
- Talks **only** to `api.anthropic.com`. Nothing is logged, stored remotely, or sent anywhere else.
- Fully open source — read [`Sources/ClaudeUsageBar.swift`](Sources/ClaudeUsageBar.swift).

## License
[MIT](LICENSE). "Claude" is a trademark of Anthropic; this project is not affiliated with Anthropic.
