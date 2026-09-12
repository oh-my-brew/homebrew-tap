class DsStore < Formula
  desc "Monitor and remove .DS_Store files"
  homepage "https://github.com/oh-my-brew/ds_store"
  url "https://github.com/oh-my-brew/ds_store/releases/download/v2026.08.29.1/ds_store-2026.08.29.1.tar.gz"
  sha256 "a8136d41859cfff47a50832f39105354334dafb6ea6b094c40ae5d9f80cbf507"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on :macos

  def install
    system "make", "build"
    bin.install Dir["bin/*"]
  end

  service do
    run [opt_bin/"ds_store", "monit"]
    keep_alive true
    log_path var/"log/ds_store.log"
    error_log_path var/"log/ds_store.error"
  end

  test do
    assert_match "ds_store monit", shell_output("#{bin}/ds_store help")
  end
end
