{
  lib,
  buildPythonApplication,
  fetchPypi,
  poetry-core,
  pyedbglib,
  pyelftools,
  pymcuprog,
  pyserial,
  pyusb,
}:

buildPythonApplication (finalAttrs: {
  pname = "pyavrocd";
  version = "2.0.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-G+frSbkcyfJ6czcf0R25SoLo0ZyGLGE12XbVjcJSON8=";
  };

  build-system = [ poetry-core ];
  dependencies = [ pyedbglib pyelftools pymcuprog pyserial pyusb ];

  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/pyavrocd" --version | grep -F '${finalAttrs.version}'
    "$out/bin/pyavrocd" --device '?' --interface updi | grep -qw avr128db48
    "$out/bin/pyavrocd" --tool '?' | grep -qw nedbg
    runHook postInstallCheck
  '';

  meta = {
    description = "GDB server for AVR microcontrollers";
    homepage = "https://pyavrocd.io/";
    license = with lib.licenses; [ mit asl20 ];
    platforms = with lib.platforms; linux ++ darwin;
    mainProgram = "pyavrocd";
  };
})
