class ClaudeUsageBar < Formula
  desc "Unofficial macOS menu-bar tracker for Claude Max/Pro usage"
  homepage "https://github.com/sagar-18/claude-usage-bar"
  license "MIT"
  version "1.0.0"

  # Builds from source (locally compiled → no Gatekeeper quarantine, no signing needed).
  head "https://github.com/sagar-18/claude-usage-bar.git", branch: "main"

  # For a pinned release, uncomment and fill in after tagging v1.0.0:
  # url "https://github.com/sagar-18/claude-usage-bar/archive/refs/tags/v1.0.0.tar.gz"
  # sha256 "REPLACE_WITH_TARBALL_SHA256"

  depends_on macos: :ventura   # macOS 13+ (SMAppService)

  def install
    system "bash", "./build.sh"
    prefix.install "ClaudeUsageBar.app"
    (bin/"claude-usage-bar").write <<~SH
      #!/bin/bash
      exec "#{opt_prefix}/ClaudeUsageBar.app/Contents/MacOS/ClaudeUsageBar" "$@"
    SH
  end

  def caveats
    <<~EOS
      ▸ Start it:      claude-usage-bar &
        or open:       open "#{opt_prefix}/ClaudeUsageBar.app"
      ▸ Then enable "Launch at Login" from the menu-bar dropdown.

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
