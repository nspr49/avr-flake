{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  hidapi,
  libusb1,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bloom";
  version = "2.1.0";

  src = fetchurl {
    url = "https://github.com/bloombloombloom/Bloom/releases/download/v${finalAttrs.version}/Bloom-headless-${finalAttrs.version}-Linux-x86_64.deb";
    hash = "sha256-u2UjVp0jaHPW+dglFPcBqPTyBV8OfkqZF/2Xy0A5v30=";
  };

  nativeBuildInputs = [ autoPatchelfHook dpkg ];
  buildInputs = [ stdenv.cc.cc.lib hidapi libusb1 qt6.qtbase ];
  dontWrapQtApps = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    dpkg-deb -x "$src" unpacked
    mkdir -p "$out/bin" "$out/libexec/bloom/bin" "$out/libexec/bloom/lib"
    install -m755 unpacked/opt/bloom/bin/bloom "$out/libexec/bloom/bin/"
    # Bloom resolves its target descriptions relative to the real executable.
    cp -r unpacked/opt/bloom/resources "$out/libexec/bloom/"
    # Keep the upstream yaml-cpp ABI; use Nixpkgs for USB and Qt libraries.
    cp -P unpacked/opt/bloom/lib/libyaml-cpp.so.0.7* "$out/libexec/bloom/lib/"
    ln -s ../libexec/bloom/bin/bloom "$out/bin/bloom"
    runHook postInstall
  '';

  preFixup = ''
    addAutoPatchelfSearchPath "$out/libexec/bloom/lib"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/bloom" --version | grep -F '${finalAttrs.version}'
    test -f "$out/libexec/bloom/resources/TargetDescriptionFiles/AVR8/AVR128DB48.xml"
    runHook postInstallCheck
  '';

  meta = {
    description = "Headless on-chip debugger and GDB server for AVR and RISC-V";
    homepage = "https://bloom.oscillate.io/";
    license = lib.licenses.lgpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bloom";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
