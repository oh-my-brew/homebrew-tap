class Omcli < Formula
  desc "Unified macOS CLI for screen locking and disk snapshots"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.09.24.1/omcli-2026.09.24.1.tar.gz"
  sha256 "c3f16c922d6e3fa61426ca2bd06ab32ad220d38c99cbbd8767b652b7674fbc12"
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
    assert_match "xcodex", cli
  end
end
