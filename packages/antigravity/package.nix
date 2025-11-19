{
  lib,
  stdenv,
  fetchurl,
  undmg,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  installShellFiles,
  # Linux dependencies
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libsecret,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
}:

let
  version = "1.11.3-6583016683339776";

  sources = {
    x86_64-linux = {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-Al2lEvl5mnFU4sx1vAkIIBOCwazy6DePnaI1y4SlYVs=";
    };
    x86_64-darwin = {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/darwin-x64/Antigravity.dmg";
      hash = lib.fakeHash;
    };
    aarch64-darwin = {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/darwin-arm/Antigravity.dmg";
      hash = lib.fakeHash;
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "antigravity";
  inherit version;

  src = fetchurl source;

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [
      undmg
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
      copyDesktopItems
      installShellFiles
    ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus.lib
    expat
    glib
    gtk3
    libdrm
    libsecret
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
  ];

  sourceRoot = ".";

  dontBuild = true;
  dontConfigure = true;

  installPhase =
    if stdenv.hostPlatform.isDarwin then
      ''
        runHook preInstall

        mkdir -p $out/Applications
        cp -r Antigravity.app $out/Applications/

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        # Install application files
        mkdir -p $out/libexec/antigravity $out/bin
        cp -r Antigravity/* $out/libexec/antigravity/

        # Create symlink
        ln -s $out/libexec/antigravity/bin/antigravity $out/bin/antigravity

        # Install icon
        mkdir -p $out/share/pixmaps
        cp $out/libexec/antigravity/resources/app/resources/linux/code.png $out/share/pixmaps/antigravity.png

        # Install shell completions
        installShellCompletion --bash $out/libexec/antigravity/resources/completions/bash/antigravity
        installShellCompletion --zsh $out/libexec/antigravity/resources/completions/zsh/_antigravity

        runHook postInstall
      '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Override VSCODE_PATH in the wrapper script
    sed -i "/ELECTRON=/iVSCODE_PATH='$out/libexec/antigravity'" $out/bin/antigravity
    grep -q "VSCODE_PATH='$out/libexec/antigravity'" $out/bin/antigravity

    # Patch ELF to add required libraries
    patchelf \
      --add-needed ${mesa}/lib/libGLESv2.so.2 \
      --add-needed ${mesa}/lib/libGL.so.1 \
      --add-needed ${mesa}/lib/libEGL.so.1 \
      $out/libexec/antigravity/antigravity
  '';

  desktopItems = lib.optionals stdenv.hostPlatform.isLinux [
    (makeDesktopItem {
      name = "antigravity";
      desktopName = "Antigravity";
      comment = "Agents that help you achieve liftoff";
      genericName = "AI Code Editor";
      exec = "antigravity %F";
      icon = "antigravity";
      startupNotify = true;
      categories = [
        "Development"
        "IDE"
      ];
      mimeTypes = [
        "text/plain"
        "inode/directory"
      ];
      keywords = [
        "vscode"
        "editor"
        "ai"
      ];
    })
  ];

  meta = with lib; {
    description = "Agents that help you achieve liftoff";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [ ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "antigravity";
  };
}
