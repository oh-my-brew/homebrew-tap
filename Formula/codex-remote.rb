class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.07.6/codex-remote-2026.09.07.6.tar.gz"
  sha256 "cc8249ed01fd996e3a40f43297eab9f4c0d5ac09c79453368f0b0011c1be1230"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on :macos

  def install
    bin.install "codex-remote"
  end

  test do
    assert_match "codex-remote #{version}", shell_output("#{bin}/codex-remote --version")
    help_output = shell_output("#{bin}/codex-remote --help")
    assert_match "Running without a command is read-only", help_output
    assert_match "start [--force]", help_output
    assert_match "update VERSION", help_output
    refute_match(/^\s+(enable|reset)/, help_output)
  end
end
