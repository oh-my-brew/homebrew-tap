class Omcli < Formula
  desc "Unified macOS CLI for screen locking, disk snapshots, and Codex"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.09.11.1/omcli-2026.09.11.1.tar.gz"
  sha256 "638a29457d0fc5c33861dc2348f1055fb9db3ec1af65a7372788076e4a28bcab"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on :macos
  depends_on "ncdu"

  def install
    system "make", "build"
    libexec.install "bin/omcli", "bin/omcli-lockscreen"
    bin.write_exec_script libexec/"omcli"
  end

  test do
    assert_match "omcli #{version}", shell_output("#{bin}/omcli --version")
    assert_match "Usage:", shell_output("#{bin}/omcli --help")
    assert_predicate libexec/"omcli-lockscreen", :executable?

    cli = (libexec/"omcli").read
    assert_match "lockscreen", cli
    assert_match "ncdu", cli
    assert_match "codex", cli
    assert_match "xcodex", cli
  end
end
