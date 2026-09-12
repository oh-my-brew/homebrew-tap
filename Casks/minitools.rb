cask "minitools" do
  version "2026.09.09.2"
  sha256 "80c6011dfdbc3605e9f0bebcc394120063cb280f16ea16a01c388be900cc8641"

  url "https://github.com/oh-my-brew/miniTools/releases/download/v#{version}/miniTools-#{version}.zip"
  name "miniTools"
  desc "Clipboard conversion, Safari window switching, and window management utility"
  homepage "https://github.com/oh-my-brew/miniTools"

  livecheck do
    url :url
    strategy :github_latest
  end

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
