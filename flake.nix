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
          pkgs = import nixpkgs { inherit system; };
          avr = pkgs.pkgsCross.avr;
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
          pyavrocd = pkgs.python3Packages.callPackage ./pyavrocd.nix { };
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
            shellHook = ''
              # Build once in the writable checkout, never in a Nix postInstall
              # sandbox. Use a subshell to preserve the caller's cwd, and keep
              # stdout clean for tools that enter via in-env.
              (
                root=$PWD
                while [ ! -f "$root/flake.nix" ] || [ ! -f "$root/cmake/avr-toolchain.cmake" ]; do
                  [ "$root" != / ] || exit 0
                  root=$(dirname "$root")
                done
                cd "$root" || exit 1
                # Let desktop VS Code run clangd directly, without a Nix launcher.
                mkdir -p .nix-tools
                ln -sfn ${pkgs.clang-tools}/bin/clangd .nix-tools/clangd
                if [ ! -s build/avr128db48_project.elf ] ||
                   [ ! -s build/avr128db48_project.hex ] ||
                   [ ! -s build/compile_commands.json ]; then
                  printf '%s\n' 'Preparing the initial firmware build...'
                  if ! { cmake --preset course && cmake --build --preset course; }; then
                    printf '%s\n' 'Initial firmware build failed; fix the error and rebuild with cmake --preset course && cmake --build --preset course.'
                  fi
                fi
              ) >&2
            '';
          });
        in {
          shells = {
            default = shell [ ];
            debug = shell [ pkgs.gdb pyavrocd ];
          };
          packages = { inherit pyavrocd; };
          checks.firmware = pkgs.runCommand "mpt-firmware-smoke-test" (toolVars // {
            nativeBuildInputs = [ toolEnv ];
          }) ''
            export HOME="$TMPDIR"
            cp -R ${firmwareSource} workspace
            chmod -R u+w workspace
            cd workspace
            cmake --preset course
            test -s build/compile_commands.json
            clangd --check=src/main.c \
              --query-driver='/nix/store/*-mpt-dev-tools/bin/avr-gcc,/nix/store/*-mpt-dev-tools/bin/avr-g++,/nix/store/*-avr-gcc-wrapper-*/bin/avr-gcc,/nix/store/*-avr-gcc-wrapper-*/bin/avr-g++'
            cmake --build --preset course
            avr-readelf -h build/avr128db48_project.elf | grep 'avr:104'
            avrdude -c dryrun -p avr128db48 -U flash:w:build/avr128db48_project.hex:i
            mkdir -p "$out"
            cp build/avr128db48_project.{elf,hex} "$out/"
          '';
        });
    in {
      devShells = forSystems (system: environments.${system}.shells);
      checks = forSystems (system: environments.${system}.checks);
      packages = forSystems (system: environments.${system}.packages);
    };
}
