class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.07.5/codex-remote-2026.09.07.5.tar.gz"
  sha256 "2a3eb37d1ee8acf27825a77bae26636ea34d2bc3dd0f24fd63170ccc8594b645"
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
