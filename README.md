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
- 🔀 **Two providers** — track **Claude** (default) or **OpenAI Codex** usage; switch anytime from the menu (Provider). Codex reads your existing `codex` CLI login from `~/.codex/auth.json` and adapts to your plan: Plus/Pro show 5-hour + weekly windows, Go shows its monthly window, Business/Enterprise seats (which OpenAI meters centrally, exposing no personal windows) get an explanatory note. Menu-bar glyph tells you which is active: ◐ Claude · ⬡ Codex
- 🎯 Exact **session / weekly / scoped** percentages (same numbers as the claude.ai usage page)
- 🎨 **9 themes** — Ocean (default), Severity, Claude, Per-Metric, Minimal, Catppuccin, Nord, Dracula, Terminal
- 🧩 **4 dropdown layouts** — Classic (default), Rings (Apple Watch-style gauges), Segments (threshold-marked cells), Trend + forecast ("at this pace: 100% ≈ Sat 2 PM", from locally kept history)
- 📏 **4 menu-bar styles** — 5-hour session only (`◐ 5h 2%`, default), Compact (`◐ 8%`, worst limit), Full (`◐ 5h 2% · wk 4% · Fab 8%`), or a tiny Ring icon (~18px) — narrow styles fit crowded/notched menu bars
- ⏱️ **Reset countdowns** per limit
- 🟢 Color-coded status (Healthy → Moderate → High → Critical)
- ⚠️ **Honest about staleness** — expired Claude Code sign-in shows a `⚠︎` on the icon and a warning row (never stale numbers passing as live), plus an "Updated Xm ago" line and auto-refresh on wake from sleep
- 🔁 **Launch at Login** — on by default from first run (modern `SMAppService`, no LaunchAgents); toggle it off from the menu anytime
- ⬆️ **In-app updates** — checks GitHub releases daily; one click runs `brew reinstall` and relaunches (no Sparkle, no downloaded binaries)
- 🪶 Native Swift/AppKit, ~single file, no dependencies, no telemetry

## Requirements
- macOS 13+ (Ventura or later)
- An existing **Claude Code** login (run `claude` once and sign in). The app reads the token from your Keychain — it never asks for credentials.
- *(Optional, for Codex tracking)* an existing **Codex CLI** login (run `codex` once and sign in) — read from `~/.codex/auth.json`.
- Xcode Command Line Tools (`xcode-select --install`) — only needed to build.

## Install

### Homebrew (builds from source — no Gatekeeper prompts, single repo)
```bash
brew tap sagar-18/claude-usage-bar https://github.com/sagar-18/claude-usage-bar
brew install --HEAD sagar-18/claude-usage-bar/claude-usage-bar
claude-usage-bar            # start it (launches detached; survives terminal close)
```
Everything lives in this one repo — the [formula](Formula/claude-usage-bar.rb) ships right here in `Formula/`, and `brew tap` points at this repo directly (no separate `homebrew-tap` repo). Launch at Login is enabled automatically on first run (toggle it from the menu).

To update later: the app checks GitHub daily and shows **"Update to X.Y.Z available…"** in its menu — one click rebuilds via brew and relaunches. Or manually: `brew update && brew reinstall claude-usage-bar`.

### Manual
```bash
git clone https://github.com/sagar-18/claude-usage-bar
cd claude-usage-bar
./build.sh
open ClaudeUsageBar.app
```

## Troubleshooting

### Installed it, but no ◐ icon in the menu bar?

The app is almost certainly running fine — macOS is just not showing it. Check in this order:

1. **Confirm it's running.** Open **Activity Monitor** and search for `ClaudeUsageBar` (or run `pgrep -fl ClaudeUsageBar` in a terminal). If it's not there, start it: `claude-usage-bar`.
2. **If it IS running, your menu bar is out of space.** macOS silently hides menu-bar icons that don't fit — no error, no indicator. This is especially common on **notched MacBooks** (13"/14"/16" M-series), where the notch eats the middle of the bar. Quit or hide a few menu-bar apps you don't need and ◐ will appear.
3. **Move it somewhere safer.** Hold **⌘ (Command) and drag** the ◐ icon to the right, near the clock — when space runs out, macOS drops the left-most status icons first, so right = priority.
4. **Fullscreen hides everything.** If the frontmost app is fullscreen, the entire menu bar (and every icon) is hidden — move the pointer to the top of the screen or exit fullscreen.
5. **Still cramped?** A menu-bar manager like [Ice](https://github.com/jordanbaird/Ice) (free, `brew install --cask jordanbaird-ice`) or Bartender lets you pin ◐ and tuck the rest away. Also try a narrower style: ◐ menu → **Menu Bar Style** (the default is the narrow *5-hour session only*).

### Numbers look stale / icon shows ⚠︎?

Your Claude Code sign-in token expired (it lives ~12h and only Claude Code can renew it). Open a terminal, run `claude`, let it load, then click **Refresh now** in the ◐ menu.

## Privacy
- Reads the OAuth token from the macOS Keychain item `Claude Code-credentials` (created by Claude Code itself).
- Talks **only** to `api.anthropic.com`. Nothing is logged, stored remotely, or sent anywhere else.
- Fully open source — read [`Sources/ClaudeUsageBar.swift`](Sources/ClaudeUsageBar.swift).

## License
[MIT](LICENSE). "Claude" is a trademark of Anthropic; this project is not affiliated with Anthropic.
