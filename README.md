# Claude Usage Bar

> [!NOTE]
> ## 🏁 This project has moved → [**AIdometer**](https://github.com/sagar-18/AIdometer)
> Renamed when it outgrew tracking only Claude (it now tracks OpenAI Codex too) — and to end the name clash with an unrelated app. **All development continues at [sagar-18/AIdometer](https://github.com/sagar-18/AIdometer).** Existing installs keep working, but won't receive new features; to migrate:
> ```bash
> brew uninstall claude-usage-bar && brew untap sagar-18/claude-usage-bar
> brew tap sagar-18/aidometer https://github.com/sagar-18/AIdometer
> brew install --HEAD sagar-18/aidometer/aidometer
> ```


A tiny, beautiful **macOS menu-bar tracker** for your **Claude** *and* **OpenAI Codex** usage — session, weekly, and scoped limits live in your menu bar, with color-coded themes and a one-click switch between providers.

```
◐ 5h 2% · wk 4% · Fab 8%      (Claude)
⬡ 5h 12% · wk 34%             (Codex)
```

Click it for a full breakdown: per-limit progress bars, reset countdowns, the active limit, and Codex token/turn activity. Switch between Claude (◐) and Codex (⬡) with the brand-mark toggle in the header — no config, it just reads the logins you already have.

---

> [!IMPORTANT]
> **Unofficial. Not affiliated with, or endorsed by, Anthropic or OpenAI.**
> This reads **your own** usage using **your own** local logins — the Claude Code token from your Keychain and/or the Codex CLI token from `~/.codex/auth.json` — by calling **undocumented** endpoints (`api.anthropic.com/api/oauth/usage`, `chatgpt.com/backend-api/wham/…`) that may change or be removed at any time. It polls gently (every 5 min by default, with exponential backoff) to respect rate limits. No data leaves your machine; there is no server, telemetry, or account beyond your existing logins.

> [!WARNING]
> **Use at your own risk — no warranty, no liability.**
> This software is provided **"as is"**, without warranty of any kind. The author and contributors are **not responsible or liable** for anything that happens to your Claude/Anthropic or ChatGPT/OpenAI account — including but not limited to rate limiting, throttling, suspension, or termination — arising from the use of this application or the undocumented endpoints it calls. It relies on an unofficial, undocumented API that can change or break without notice. **By installing or using it, you accept full responsibility.** If you are unsure, don't use it.

---

## Features
- 🔀 **Two providers** — track **Claude** (default) or **OpenAI Codex** usage; switch instantly with the brand-mark toggle in the dropdown header. Codex reads your existing `codex` CLI login from `~/.codex/auth.json` and adapts to your plan: Plus/Pro show 5-hour + weekly windows, Go shows its monthly window, Business/Enterprise seats (which OpenAI meters centrally, exposing no personal windows) fall back to token/turn activity from the analytics API. Menu-bar glyph tells you which is active: ◐ Claude · ⬡ Codex
- 🎯 Exact **session / weekly / scoped** percentages (same numbers as the claude.ai usage page)
- 🎨 **9 themes** — Ocean (default), Severity, Claude, Per-Metric, Minimal, Catppuccin, Nord, Dracula, Terminal
- 🧩 **4 dropdown layouts** — Classic (default), Rings (Apple Watch-style gauges), Segments (threshold-marked cells), Trend + forecast ("at this pace: 100% ≈ Sat 2 PM", from locally kept history)
- 📏 **4 menu-bar styles** — 5-hour session only (`◐ 5h 2%`, default), Compact (`◐ 8%`, worst limit), Full (`◐ 5h 2% · wk 4% · Fab 8%`), or a tiny Ring icon (~18px) — narrow styles fit crowded/notched menu bars
- ⏱️ **Reset countdowns** per limit
- 🟢 Color-coded status (Healthy → Moderate → High → Critical)
- ⚠️ **Honest about staleness** — expired Claude Code sign-in shows a `⚠︎` on the icon and a warning row (never stale numbers passing as live), plus an "Updated Xm ago" line and auto-refresh on wake from sleep
- 🔁 **Launch at Login** — on by default from first run (modern `SMAppService`, no LaunchAgents); toggle it off from the menu anytime
- ⬆️ **In-app updates** — checks GitHub on launch, menu-open, and wake; shows a blue `↑` on the menu-bar icon and an "Update available…" row when a new version exists; one click runs `brew reinstall` and relaunches (no Sparkle, no downloaded binaries)
- ⚙️ **Live settings** — Theme, Layout, Menu Bar Style, and Auto Refresh live in a Settings panel that opens beside the menu; picking an option applies instantly without closing the menu
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

To update later: the app checks GitHub automatically (on launch, when you open the menu, and on wake) and flags a new release with a blue **↑** on the menu-bar icon plus an **"Update to X.Y.Z available…"** row — one click rebuilds via brew and relaunches. Or manually: `brew update && brew reinstall claude-usage-bar`.

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

Your sign-in token expired (tokens live ~12h and only the CLI that created them can renew). Open a terminal and run `claude` (for Claude) or `codex` (for Codex), let it load, then click **Refresh now** in the menu.

### On Codex, the dropdown shows token activity instead of percentage bars?

That's expected on **Business/Enterprise** seats — OpenAI meters those centrally and exposes no personal rate-limit windows (its own `/status` shows nothing either). The app falls back to showing your **token & turn activity** (Today / Last 7 days) from the analytics API. **Plus, Pro, and Go** accounts get the normal percentage bars.

## Privacy
- Claude: reads the OAuth token from the macOS Keychain item `Claude Code-credentials` (created by Claude Code itself) and talks only to `api.anthropic.com`.
- Codex: reads the OAuth token from `~/.codex/auth.json` (created by the Codex CLI) and talks only to `chatgpt.com`.
- Nothing is logged, stored remotely, or sent anywhere else.
- Fully open source — read [`Sources/ClaudeUsageBar.swift`](Sources/ClaudeUsageBar.swift).

## License
[MIT](LICENSE). "Claude" is a trademark of Anthropic; "Codex", "ChatGPT", and the OpenAI logo are trademarks of OpenAI. This project is not affiliated with either company; marks are used only to identify the services being monitored.
