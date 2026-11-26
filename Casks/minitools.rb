cask "minitools" do
  version "2026.11.24.3"
  sha256 "b0382009d8b7cd4e6fcb39b037509a54c205e4454b11a84ac8e96769bf2ece21"

  url "https://github.com/oh-my-brew/miniTools/releases/download/v#{version}/miniTools-#{version}.zip"
  name "miniTools"
  desc "Clipboard conversion, Safari window switching, and window management utility"
  homepage "https://github.com/oh-my-brew/miniTools"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :tahoe

  app "miniTools.app"

  uninstall quit: "com.omzcj.minitools"

  zap trash: "~/Library/Preferences/com.omzcj.minitools.plist"

  caveats <<~EOS
    miniTools requires Accessibility permission for Safari window switching
    and window management. Mouse side-button bindings also require Input
    Monitoring permission. Closed-lid running requires one-time approval for
    the miniTools background service in System Settings.
  EOS
end
