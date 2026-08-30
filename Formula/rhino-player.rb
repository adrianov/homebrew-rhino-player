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
  depends_on "hicolor-icon-theme"
  depends_on "libadwaita"
  depends_on "mpv"

  def install
    # Dev builds use LLD via .cargo/config.toml; Homebrew's clang shim rejects -fuse-ld=lld.
    rm_r ".cargo" if (buildpath/".cargo").exist?

    system "cargo", "install", *std_cargo_args

    man1.install "doc/rhino-player.1"
    (share/"rhino-player/vs").install Dir["data/vs/*.vpy"]
    # Runtime IconTheme prepend (symbolics + app id when the platform hicolor is empty).
    (share/"rhino-player/icons").mkpath
    cp_r "data/icons/hicolor", share/"rhino-player/icons/"
    # Standard Freedesktop tree (same layout as the .deb) for GTK / shell app icons.
    (share/"icons/hicolor").mkpath
    cp_r "data/icons/hicolor/.", share/"icons/hicolor"
    (share/"applications").install "data/applications/ch.rhino.RhinoPlayer.desktop"
    (share/"metainfo").install "data/metainfo/ch.rhino.RhinoPlayer.metainfo.xml"

    return unless OS.mac?

    install_macos_app
  end

  def install_macos_app
    app = prefix/"Rhino Player.app"
    contents = app/"Contents"
    macos = contents/"MacOS"
    resources = contents/"Resources"
    macos.mkpath
    (resources/"share/rhino-player/vs").mkpath
    (resources/"data/icons").mkpath

    # Binary lives inside the bundle so Launch Services / Dock use AppIcon.icns.
    mv bin/"rhino-player", macos/"rhino-player"
    bin.install_symlink macos/"rhino-player"

    inreplace "packaging/macos/Info.plist.in", "@VERSION@", version.to_s
    cp "packaging/macos/Info.plist.in", contents/"Info.plist"
    cp Dir["data/vs/*.vpy"], resources/"share/rhino-player/vs/"
    cp_r "data/icons/hicolor", resources/"data/icons/"

    iconset = buildpath/"AppIcon.iconset"
    iconset.mkpath
    hicon = buildpath/"data/icons/hicolor"
    cp hicon/"16x16/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_16x16.png"
    cp hicon/"32x32/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_16x16@2x.png"
    cp hicon/"32x32/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_32x32.png"
    cp hicon/"64x64/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_32x32@2x.png"
    cp hicon/"128x128/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_128x128.png"
    cp hicon/"256x256/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_128x128@2x.png"
    cp hicon/"256x256/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_256x256.png"
    cp hicon/"512x512/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_256x256@2x.png"
    cp hicon/"512x512/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_512x512.png"
    cp hicon/"1024x1024/apps/ch.rhino.RhinoPlayer.png", iconset/"icon_512x512@2x.png"
    system "iconutil", "-c", "icns", iconset.to_s, "-o", (resources/"AppIcon.icns").to_s

    # Ad-hoc sign so Launch Services binds Info.plist + sealed AppIcon.icns.
    system "codesign", "--force", "--sign", "-", "--timestamp=none", app.to_s
  end

  def caveats
    s = <<~EOS
      Smooth Video (~60 FPS) needs MVTools in addition to Homebrew mpv:
        brew install vapoursynth-mvtools
    EOS
    if OS.mac?
      s += <<~EOS

        macOS app bundle (Dock / Launchpad icon):
          #{opt_prefix}/Rhino\\ Player.app
        Optional: ln -s "#{opt_prefix}/Rhino Player.app" /Applications/
      EOS
    end
    s
  end

  post_install_steps do
    update_gtk_icon_cache
  end

  test do
    assert_match "Help Options", shell_output("#{bin}/rhino-player --help")
    assert_path_exists man1/"rhino-player.1"
    assert_path_exists share/"rhino-player/vs/rhino_60_mvtools.vpy"
    assert_path_exists share/"icons/hicolor/256x256/apps/ch.rhino.RhinoPlayer.png"
    assert_path_exists share/"applications/ch.rhino.RhinoPlayer.desktop"
    return unless OS.mac?

    assert_path_exists prefix/"Rhino Player.app/Contents/Resources/AppIcon.icns"
    assert_path_exists prefix/"Rhino Player.app/Contents/MacOS/rhino-player"
  end
end
