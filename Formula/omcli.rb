class Omcli < Formula
  desc "Unified macOS CLI for screen locking, disk snapshots, and Sidecar"
  homepage "https://github.com/oh-my-brew/omcli"
  url "https://github.com/oh-my-brew/omcli/releases/download/v2026.09.25.1/omcli-2026.09.25.1.tar.gz"
  sha256 "b5d874d84cd7e94621ab07014fa779dc32137e40e761266aa31934e100506442"
  license all_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on :macos
  depends_on "ncdu"

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
    assert_match "xcodex", cli
  end
end
