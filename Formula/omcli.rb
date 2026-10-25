class Omcli < Formula
  desc "Unified macOS CLI for screen lock, snapshots, Sidecar, and device tools"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.25.3/omcli-2026.10.25.3.tar.gz"
  sha256 "6acd4ab574a592f1e6c726bc8fbdb1beefc36103ed2dd5f34ad51e63f5adf63b"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.25.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "3b7eb61b8fab98aaa661506105eec73d5ff0eaa9a8e17c5608b47871cd397e58"
  end

  depends_on arch: :arm64
  depends_on "libusbmuxd"
  depends_on :macos
  depends_on "ncdu"

  def install
    libexec.install Dir["bin/*"]
    bin.write_exec_script libexec/"omcli"
  end

  test do
    assert_match "omcli #{version}", shell_output("#{bin}/omcli --version")
    assert_match "Usage:", shell_output("#{bin}/omcli --help")
    assert_predicate libexec/"omcli-lockscreen", :executable?
    assert_predicate libexec/"omcli-sidecar", :executable?

    cli = (libexec/"omcli").read
    assert_match "lockscreen", cli
    assert_match "ncdu", cli
    assert_match "sidecar", cli
    assert_match "iphone", cli
    assert_match "codex", cli
  end
end
