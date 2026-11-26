class Scaletail < Formula
  desc "Tailscale CLI and daemon installed with scaletail command names"
  homepage "https://tailscale.com"
  url "https://github.com/tailscale/tailscale.git",
      tag:      "v1.104.7",
      revision: "cbc74fe48ef1b1649f69a4d9a602319427e25102"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/oh-my-brew/homebrew-tap/releases/download/scaletail-v1.104.7"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "409df3c0718ad81debee1646b8714d01188c6b4e3599d213440d6a2df4725746"
  end

  depends_on "go" => :build

  conflicts_with "tailscale", because: "both run the same Tailscale service"
  conflicts_with cask: "tailscale-app"

  def install
    vars = Utils.safe_popen_read("./build_dist.sh", "shellvars")
    long_stamp = vars.match(/VERSION_LONG="(.*)"/)[1]
    short_stamp = vars.match(/VERSION_SHORT="(.*)"/)[1]
    commit_stamp = vars.match(/VERSION_GIT_HASH="(.*)"/)[1]
    ldflags = %W[
      -X tailscale.com/version.longStamp=#{long_stamp}
      -X tailscale.com/version.shortStamp=#{short_stamp}
      -X tailscale.com/version.gitCommitStamp=#{commit_stamp}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/tailscale"
    system "go", "build", *std_go_args(ldflags:, output: bin/"scaletaild"), "./cmd/tailscaled"

    generate_completions_from_executable(bin/"scaletail", shell_parameter_format: :cobra)
  end

  def caveats
    on_linux do
      <<~EOS
        scaletaild needs root privileges to configure iptables/nftables and DNS.
        Start the root service with:
          sudo --preserve-env=HOME brew services start scaletail

        To run without root, use userspace-networking mode:
          scaletaild --tun=userspace-networking
      EOS
    end
  end

  service do
    run opt_bin/"scaletaild"
    require_root true
    keep_alive true
    log_path var/"log/scaletaild.log"
    error_log_path var/"log/scaletaild.log"
  end

  test do
    version_text = shell_output("#{bin}/scaletail version")
    assert_match version.to_s, version_text
    assert_match(/commit: [a-f0-9]{40}/, version_text)

    spawn bin/"scaletaild", "-tun=userspace-networking", "-socket=#{testpath}/scaletaild.socket"
    sleep 2
    assert_match "Logged out.", shell_output("#{bin}/scaletail --socket=#{testpath}/scaletaild.socket status", 1)
  end
end
