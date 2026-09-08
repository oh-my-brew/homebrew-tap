class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/archive/refs/tags/v2026.09.08.3.tar.gz"
  version "2026.09.08.3"
  sha256 "576d4d98e0fd0cde875b2270a0657b58011e1df083767da58799f85c429a08ec"
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
    assert_match "start                  Converge", help_output
    assert_match "update VERSION", help_output
    refute_match(/^\s+(enable|reset)/, help_output)
  end
end
