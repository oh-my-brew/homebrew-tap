cask "minitools" do
  version "2026.11.11.2"
  sha256 "58b0c04b689d487c54882a0bbdf5a15863ef5408bfe5c10f56de9d7b8ddc2a72"

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
