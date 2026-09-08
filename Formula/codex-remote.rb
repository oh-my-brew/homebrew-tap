class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/archive/refs/tags/v2026.09.08.6.tar.gz"
  version "2026.09.08.6"
  sha256 "097bb99ba9e49229b541242d7089dede7dc8fe3937bf9b381a6f905ac7b1fc21"
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
