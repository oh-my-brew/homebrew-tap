class Omcli < Formula
  desc "Unified macOS CLI for screen lock, snapshots, Sidecar, and device tools"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.15.2/omcli-2026.10.15.2.tar.gz"
  sha256 "6f35f12e30e2bc6289ecd26b1be3ca1824657b8c9a8ffc6532f2e938b53f1d19"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.15.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "60a9d8bbdd4ddb2a945c654a94324dfa4c76b1f0afd6209fcabf4dd158daf8ba"
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
