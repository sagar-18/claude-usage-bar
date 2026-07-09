class ClaudeUsageBar < Formula
  desc "Unofficial macOS menu-bar tracker for Claude Max/Pro usage"
  homepage "https://github.com/sagar-18/claude-usage-bar"
  license "MIT"
  version "1.2.3"

  # Builds from source (locally compiled → no Gatekeeper quarantine, no signing needed).
  head "https://github.com/sagar-18/claude-usage-bar.git", branch: "main"

  # For a pinned release, uncomment and fill in after tagging v1.1.0:
  # url "https://github.com/sagar-18/claude-usage-bar/archive/refs/tags/v1.1.0.tar.gz"
  # sha256 "REPLACE_WITH_TARBALL_SHA256"

  depends_on macos: :ventura   # macOS 13+ (SMAppService)

  def install
    system "bash", "./build.sh"
    prefix.install "ClaudeUsageBar.app"
    (bin/"claude-usage-bar").write <<~SH
      #!/bin/bash
      # Launch detached via LaunchServices so it keeps running after the terminal closes.
      exec open "#{opt_prefix}/ClaudeUsageBar.app"
    SH
  end

  def caveats
    <<~EOS
      ▸ Start it:      claude-usage-bar
        or open:       open "#{opt_prefix}/ClaudeUsageBar.app"
      ▸ Launch at Login is enabled automatically on first run
        (toggle it from the menu-bar dropdown).
      ▸ No ◐ icon? Your menu bar is likely full (macOS hides icons that
        don't fit, especially around the notch) — see Troubleshooting in
        the README. Cmd-drag the icon to the right, near the clock.

      Requires an existing Claude Code login — run `claude` once and sign in.
      The app reads your token from the Keychain; it never asks for credentials.

      Unofficial. Not affiliated with Anthropic. Provided "as is", no warranty —
      use at your own risk (see the About item / README).
    EOS
  end

  test do
    assert_predicate opt_prefix/"ClaudeUsageBar.app/Contents/MacOS/ClaudeUsageBar", :exist?
  end
end
