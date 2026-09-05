cask "chatgpt" do
  arch arm: "arm64", intel: "x64"

  version "26.818.61809"
  sha256 arm:   "36a4c47d0bdee76710c0989b9b077f3c3e88bc0ba452469b86c811cc638a00bc",
         intel: "82ee8ea29900a51ad9a355700dadd5a7baad62170d8dde005f8ee2714860befc"

  url "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-#{arch}-#{version}.zip"
  name "ChatGPT"
  desc "Pinned OpenAI ChatGPT desktop app"
  homepage "https://chatgpt.com/"

  livecheck do
    skip "Pinned to the validated ChatGPT release"
  end

  no_autobump! because: "This cask intentionally tracks a fixed ChatGPT release"

  auto_updates true
  depends_on macos: :ventura

  app "ChatGPT.app"

  postflight_steps do
    run "/usr/bin/defaults",
        args:           ["write", "com.openai.codex", "SUEnableAutomaticChecks", "-bool", "false"],
        writable_paths: ["~/Library/Preferences"]
    run "/usr/bin/defaults",
        args:           ["write", "com.openai.codex", "SUAutomaticallyUpdate", "-bool", "false"],
        writable_paths: ["~/Library/Preferences"]
  end

  uninstall quit: "com.openai.codex"

  caveats <<~EOS
    ChatGPT is intentionally pinned to #{version}. Automatic update checks are
    disabled after installation. Upgrade only by changing this cask explicitly.

    Install this tap's pinned cask with:
      brew install --cask omzcj/omzcj/chatgpt
  EOS
end
