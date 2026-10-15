class Omcli < Formula
  desc "Unified macOS CLI for screen lock, snapshots, Sidecar, and device tools"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.16.1/omcli-2026.10.16.1.tar.gz"
  sha256 "ebb565d6a71984c7958cd671e1df506ce7f4d35672ccc84381e0ad2d59a1926e"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.16.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "661209c7f5e830e0e6637ee97cdedbfe34c4057b83f9fcdf1113f4c96ac9edc1"
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
