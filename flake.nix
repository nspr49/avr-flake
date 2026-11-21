{
  description = "MPT course shell for the AVR128DB48 Curiosity Nano";

  # Stay on 26.05 while the course still needs Intel macOS support.
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

  outputs = { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forSystems = lib.genAttrs systems;
      firmwareSource = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [ ./.clangd ./CMakeLists.txt ./CMakePresets.json ./cmake ./scripts ./src ];
      };
      environments = forSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: lib.getName pkg == "vscode";
          };
          avr = pkgs.pkgsCross.avr;
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
          extensions = with pkgs.vscode-extensions; [
            llvm-vs-code-extensions.vscode-clangd
            ms-vscode.cmake-tools
          ];
          editorAvailable = lib.all (lib.meta.availableOn pkgs.stdenv.hostPlatform)
            ([ pkgs.vscode ] ++ extensions);
          vscode = pkgs.vscode-with-extensions.override { vscodeExtensions = extensions; };
          courseCode = pkgs.writeShellScriptBin "course-code" ''
            # A separate profile prevents reuse of a desktop Code process that
            # was started without the course PATH (and keeps updates separate).
            exec ${vscode}/bin/code --user-data-dir "''${XDG_DATA_HOME:-$HOME/.local/share}/mpt-vscode" "$@"
          '';
          tools = [
            avr.stdenv.cc             # AVR GCC, including binutils and avr-libc via its wrapper
            pkgs.avrdude
            pkgs.cmake
            pkgs.ninja
            pkgs.gnumake
            pkgs.clang-tools         # clangd and clang-format
            pkgs.git
            pkgs.python3
            pkgs.socat
          ] ++ lib.optionals isLinux [
            pkgs.usbutils            # lsusb for troubleshooting USB and WSL attach
          ];
          # Expose executables without mixing host package headers and setup
          # hooks into the AVR compiler environment. Keep the compiler path
          # identical across shells so all variants can share a CMake cache.
          toolEnv = pkgs.buildEnv {
            name = "mpt-dev-tools";
            paths = tools;
            pathsToLink = [ "/bin" ];
          };
          toolVars = {
            MPT_DEV_SHELL = "1";
            MPT_AVR_LIBDIR = "${avr.libc}/avr/lib/avrxmega4";
          };
          shell = extra: pkgs.mkShellNoCC (toolVars // {
            packages = [ toolEnv ] ++ extra;
          });
        in {
          shells = { default = shell [ ]; }
            // lib.optionalAttrs editorAvailable { editor = shell [ courseCode ]; }
            // lib.optionalAttrs isLinux { debug = shell [ pkgs.gdb ]; };
          checks.firmware = pkgs.runCommand "mpt-firmware-smoke-test" (toolVars // {
            nativeBuildInputs = [ toolEnv ];
          }) ''
            export HOME="$TMPDIR"
            cp -R ${firmwareSource} workspace
            chmod -R u+w workspace
            cd workspace
            cmake --preset course
            cmake --build --preset course
            avr-readelf -h build/avr128db48_project.elf | grep 'avr:104'
            avrdude -c dryrun -p avr128db48 -U flash:w:build/avr128db48_project.hex:i
            ./scripts/clangd --check=src/main.c
            mkdir -p "$out"
            cp build/avr128db48_project.{elf,hex} "$out/"
          '';
        });
    in {
      devShells = forSystems (system: environments.${system}.shells);
      checks = forSystems (system: environments.${system}.checks);
    };
}
