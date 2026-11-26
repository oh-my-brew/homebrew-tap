cask "rustdeskx" do
  version "1.5.3.1"
  sha256 "d08bba2aa74a02555adb47f98469986d23b09d3f1db82ff5acf18aa7c0ac5451"

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
