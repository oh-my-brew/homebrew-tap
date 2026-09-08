class CodexRemote < Formula
  desc "Manage ChatGPT Desktop reuse of the Codex managed app-server"
  homepage "https://github.com/omzcj/codex-remote"
  url "https://github.com/omzcj/codex-remote/archive/refs/tags/v2026.09.08.2.tar.gz"
  version "2026.09.08.2"
  sha256 "e006a391b1108a3526244cd12b5d6e46a8f6613be70f0315c761f2c0058ac5e6"
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
