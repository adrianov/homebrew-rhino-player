class RhinoPlayer < Formula
  desc "mpv-backed media player with a GTK 4 / libadwaita UI"
  homepage "https://github.com/adrianov/rhino-player"
  url "https://github.com/adrianov/rhino-player/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "7f7da938b2bc3cc0157a5ca5a1d7bdc91f2b6fe451cd3631e793168581b7f3dc"
  license "GPL-3.0-or-later"
  head "https://github.com/adrianov/rhino-player.git", branch: "main"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "gtk4"
  depends_on "libadwaita"
  depends_on "mpv"

  def install
    # Dev builds use LLD via .cargo/config.toml; Homebrew's clang shim rejects -fuse-ld=lld.
    rm_r ".cargo" if (buildpath/".cargo").exist?

    system "cargo", "install", *std_cargo_args
    man1.install "doc/rhino-player.1"
    (share/"rhino-player/vs").install Dir["data/vs/*.vpy"]
    (share/"rhino-player/icons").mkpath
    cp_r "data/icons/hicolor", share/"rhino-player/icons/"
  end

  def caveats
    <<~EOS
      Smooth Video (~60 FPS) needs MVTools in addition to Homebrew mpv:
        brew install vapoursynth-mvtools
    EOS
  end

  test do
    assert_match "Help Options", shell_output("#{bin}/rhino-player --help")
    assert_path_exists man1/"rhino-player.1"
    assert_path_exists share/"rhino-player/vs/rhino_60_mvtools.vpy"
    assert_path_exists share/"rhino-player/icons/hicolor"
  end
end
