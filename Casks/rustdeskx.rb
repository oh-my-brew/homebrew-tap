cask "rustdeskx" do
  version "1.4.9.3"
  sha256 "56264b466f834a5e3b4c312ed44ae02e1626485f96880afb800c6dd317d05260"

  url "https://github.com/oh-my-brew/rustdeskx/releases/download/v#{version}/RustDeskX-#{version}-arm64.zip"
  name "RustDeskX"
  desc "Apple Silicon RustDesk rebrand for signed and notarized distribution"
  homepage "https://github.com/oh-my-brew/rustdeskx"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :monterey

  app "RustDeskX.app"

  uninstall quit: "com.omzcj.rustdeskx"

  zap trash: "~/Library/Preferences/com.omzcj.rustdeskx.plist"

  caveats <<~EOS
    RustDeskX requires Screen & System Audio Recording and Accessibility
    permissions. Enable Input Monitoring if macOS requests it.

    For Tailscale Direct IP access, enable "Allow direct IP access" in
    RustDeskX and connect to <Tailscale-IP-or-MagicDNS-name>:21118.
  EOS
end
