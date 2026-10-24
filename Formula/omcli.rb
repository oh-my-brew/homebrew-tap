class Omcli < Formula
  desc "Unified macOS CLI for screen lock, snapshots, Sidecar, and device tools"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.21.1/omcli-2026.10.21.1.tar.gz"
  sha256 "9e814638188571fd4a4254e2f088dc236ae4683264b5788222572ac6ad56e5d3"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.21.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "b95ff221c3da1110c3ebea13ab69a3bec8d4210ac677964a4f0b80a2f4e7505c"
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
