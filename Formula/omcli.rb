class Omcli < Formula
  desc "Unified macOS CLI for screen locking, disk snapshots, and Codex"
  homepage "https://github.com/omzcj/omcli"
  url "https://github.com/omzcj/omcli/releases/download/v2026.09.09.1/omcli-2026.09.09.1.tar.gz"
  sha256 "675b3e0f301fbf56281e92d365f94833fcdc6354ba07dba35309b40df65e5e27"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

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
