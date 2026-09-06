class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.06.2/codex-remote-2026.09.06.2.tar.gz"
  sha256 "effc91acaa35510e144195cb1cf71ac78bef80ec7d88f849f850a68ae97b841c"
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
