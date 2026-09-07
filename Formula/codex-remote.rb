class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.07.3/codex-remote-2026.09.07.3.tar.gz"
  sha256 "6f3c2e67d4f42fea9dfd26319364648de45467dd0732101415e6e057c86f1505"
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
    assert_match "start [--force]", shell_output("#{bin}/codex-remote --help")
    assert_match "update VERSION", shell_output("#{bin}/codex-remote --help")
  end
end
