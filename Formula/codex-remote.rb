class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.07.2/codex-remote-2026.09.07.2.tar.gz"
  sha256 "1a3e4d2619004b229fa14d33e44e8186ea6d67c8a33a2049e2c5a16c7fb2eb6b"
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
    assert_match "Running without a command is read-only", shell_output("#{bin}/codex-remote --help")
    assert_match "update VERSION", shell_output("#{bin}/codex-remote --help")
  end
end
