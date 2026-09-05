class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.06.1/codex-remote-2026.09.06.1.tar.gz"
  sha256 "b2cff176293bba2f74c6750788e733d89e1d1f3dd60d5ec0e55a9bcb62878f63"
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
