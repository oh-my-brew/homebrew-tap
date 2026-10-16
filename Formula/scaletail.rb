class Scaletail < Formula
  desc "Tailscale CLI and daemon installed with scaletail command names"
  homepage "https://tailscale.com"
  url "https://github.com/tailscale/tailscale.git",
      tag:      "v1.102.4",
      revision: "bbcd7d1fc2054b9189ebc1531acf74bd880ca0c8"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  depends_on "go" => :build

  conflicts_with "tailscale", because: "both run the same Tailscale service"
  conflicts_with cask: "tailscale-app"

  def install
    vars = Utils.safe_popen_read("./build_dist.sh", "shellvars")
    ldflags = %W[
      -X tailscale.com/version.longStamp=#{vars.match(/VERSION_LONG="(.*)"/)[1]}
      -X tailscale.com/version.shortStamp=#{vars.match(/VERSION_SHORT="(.*)"/)[1]}
      -X tailscale.com/version.gitCommitStamp=#{vars.match(/VERSION_GIT_HASH="(.*)"/)[1]}
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
