class Omcli < Formula
  desc "Unified macOS CLI for screen locking, disk snapshots, and Codex"
  homepage "https://github.com/omzcj/omcli"
  url "https://github.com/omzcj/omcli/releases/download/v2026.09.10.1/omcli-2026.09.10.1.tar.gz"
  sha256 "63469d69b44f98ecc6d3196877d633d5bbefca23f35d4eab3fbc184c090f883e"
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
  end
end
