class Omcli < Formula
  desc "Unified macOS CLI for screen lock, snapshots, Sidecar, and device tools"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.14.1/omcli-2026.10.14.1.tar.gz"
  sha256 "57eba4f374796d76a7df1dcbf2208391a7fd9cdcf7d939e45a966fd6d818bb2d"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/omcli/releases/download/v2026.10.10.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "a06ab0732f099ea0227b727768c2d9f8d437543a719cf761a648f0b61fbc3e33"
  end

  depends_on arch: :arm64
  depends_on "libusbmuxd"
  depends_on "ncdu"
  depends_on :macos

  def install
    libexec.install "bin/omcli", "bin/omcli-lockscreen", "bin/omcli-sidecar"
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
