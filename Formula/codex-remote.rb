class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/releases/download/v2026.09.07.4/codex-remote-2026.09.07.4.tar.gz"
  sha256 "12f2ee9da874b2905f698c3b174a51375b06b3dadf47446e83f707d9e9ab1fb6"
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
