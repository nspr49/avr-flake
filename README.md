# MPT: AVR128DB48 development with Nix

Build and flash the **AVR128DB48 Curiosity Nano** without Docker or a separately installed AVR toolchain. The starter in `src/main.c` blinks the board's user LED (PB3). Edit it or add sources to the `firmware` target in `CMakeLists.txt`.

**Daily workflow:** from the course folder, run `./start`, then press **Ctrl+Shift+B** (macOS: **⌘⇧B**) to build. For first-time setup, follow the steps below.

## 1. Set up once

- **Linux and macOS:** follow the [Nix installation instructions](https://nix.dev/install-nix), then open a new terminal.
- **Windows 11:** install [WSL2](https://learn.microsoft.com/windows/wsl/install) (for example, `wsl --install -d Ubuntu`). Install Nix **inside** Ubuntu, not in PowerShell. Clone the course repo inside the Linux filesystem (e.g. `~/mpt`), not under `/mnt/c`.

Run `nix --version` to check the installation. `./start` handles the Nix flags for you. If you also want to run `nix develop` or `nix flake check` directly, add this line to `~/.config/nix/nix.conf` (create the directory/file if missing):

```ini
extra-experimental-features = nix-command flakes
```

Alternatively, add `--extra-experimental-features 'nix-command flakes'` right after `nix` in the commands below. No AVR packages need to be installed globally. The first run downloads the pinned tools; the shell does not build, launch an editor, change USB permissions, or touch a board on entry.

## 2. Build firmware

From the repo root:

```sh
nix develop
cmake --preset course
cmake --build --preset course
```

This produces `build/avr128db48_project.hex` for flashing and `build/avr128db48_project.elf` with symbols. The preset also generates `build/compile_commands.json` for clangd. For another editor, use `scripts/clangd` as the language server. Type `exit` to leave the shell.

## 3. Open VS Code

From the repo root, run `./start`. You don't need to enter `nix develop` first.

**Linux desktop or macOS:** the launcher opens a separate course profile with Microsoft VS Code and pinned clangd and CMake Tools extensions from `vscode-with-extensions`. Press **Ctrl+Shift+B** (**⌘⇧B** on macOS) to configure and build. The first build creates the compilation database. To use the CMake Tools commands instead, select the `course` configure/build preset. If you update `flake.lock`, quit all course Code windows before relaunching.

**Windows 11 / WSL2:** install Windows VS Code and the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl). Run `./start` from your WSL terminal. If Windows VS Code is not on your WSL `PATH`, use **WSL: Open Folder in WSL** from VS Code instead. Verify the bottom-left status shows **WSL**. Install the two recommended extensions **in WSL**, then use **Ctrl+Shift+B**. VS Code and its extensions are not pinned in this fallback; the build, language server, and flashing tools still come from the same `flake.lock`. Workspace scripts enter the Nix environment even when the editor was not launched from `nix develop`. You can also use this fallback with an existing editor on Linux or macOS.

## 4. Flash the Curiosity Nano

Flash only when you're ready to replace the board's existing application. Connect one board with a USB **data** cable. The onboard nEDBG uses the AVRDUDE programmer `pkobn_updi` and USB ID `03eb:2175`. An external programmer or a different board may require different settings.

### Linux: one-time USB permissions

Run as your normal user, **outside** the Nix shell:

```sh
./hardware/install-udev
```

The installer explicitly asks for sudo. It installs `hardware/70-mpt-curiosity-nano.rules` in `/etc/udev/rules.d`, creates the `mpt-avr` group, adds your account, and reloads the rules. The rule grants access only to the matching programmer's USB and hidraw devices, not all USB devices. Sign out and back in, then reconnect the board. On a managed lab PC, ask your administrator to apply the rule and grant access instead. On NixOS, declare the rule via `services.udev.extraRules` and the `mpt-avr` group/membership in your system configuration.

### macOS: no udev

Connect the board directly and approve the USB accessory prompt if macOS shows one. Check `system_profiler SPUSBDataType` if the board isn't detected.

### WSL2: Linux permissions plus Windows USB forwarding

1. Check `ps -p 1 -o comm=` in Ubuntu. If it isn't `systemd`, add the following to `/etc/wsl.conf` in Ubuntu (merge with existing settings), then run `wsl --shutdown` in PowerShell and reopen Ubuntu. Run the Linux USB permissions installer above in Ubuntu, then restart the WSL session so group membership takes effect.

   ```ini
   [boot]
   systemd=true
   ```

2. Install [usbipd-win](https://learn.microsoft.com/windows/wsl/connect-usb), keep Ubuntu running, and use PowerShell. Replace `<BUSID>` with the ID shown for the board (`03eb:2175`):

   ```powershell
   usbipd list
   usbipd bind --busid <BUSID>      # Administrator; one-time sharing
   usbipd attach --wsl --busid <BUSID>  # Attach after reconnecting/restarting WSL
   ```

3. In Ubuntu inside `nix develop`, check `lsusb -d 03eb:2175`. If the device is absent, Nix and udev cannot fix the Windows forwarding. If forwarding is unavailable on your machine, build in WSL and flash on a lab PC.

### Program the board

From the repo root inside `nix develop`:

```sh
avrdude -c pkobn_updi -p avr128db48 -P usb -U flash:w:build/avr128db48_project.hex:i
```

Or explicitly run **Tasks: Run Task → Flash Curiosity Nano** in VS Code; it builds first. Don't run AVRDUDE with sudo. If Linux sees the board with `lsusb` but AVRDUDE can't open it, check `id -nG` for `mpt-avr`, reconnect the board, and close other software using the programmer. If you just want to test the build and HEX without hardware, run `nix flake check`.

## Platform and debugging notes

| Host | Course tools and editor |
| --- | --- |
| `x86_64-linux` | Firmware build, clangd and AVRDUDE dry-run tested. Managed VS Code CLI and extension list tested. |
| `aarch64-linux` | Shell and editor evaluate; native execution and USB still need testing. |
| `x86_64-darwin`, `aarch64-darwin` | Shell and editor evaluate; native execution and USB still need testing. Nixpkgs 26.05 is the last series supporting Intel Macs. |
| Windows 11 | Use the matching Linux shell in WSL2. Windows VS Code + WSL is the recommended UI; USB forwarding and the full WSL flow still need testing. No native Windows flake output. |

The default shell provides AVR GCC/binutils and avr-libc (including AVR128DB48 headers and startup code), CMake, Ninja, Make, clangd/clang-format, Git, Python, socat, and AVRDUDE. `lsusb` and the optional GDB shell are Linux-only. The separate editor shell allows unfree VS Code and, on x86_64 Linux, the pinned Microsoft C/C++ debug adapter. clangd still provides language features. Nixpkgs also packages VSCodium, but it is not configured here; this setup matches the course's VS Code extensions and keeps the Microsoft WSL integration as the Windows fallback.

## Optional: live debugging with Bloom

On **x86_64 Linux**, the optional `.#debug` shell provides **Bloom 2.1.0 (headless)** and GDB. `bloom.yaml` selects the AVR128DB48 Curiosity Nano's onboard UPDI debugger and binds the GDB server to `127.0.0.1:1442`. Bloom is not included in `./start` or the default shell. This flake does not package Bloom for ARM Linux or macOS. On x86_64 WSL2, the same shell is available, but live debugging with USB forwarding has not been tested.

### In VS Code

1. Open the project with `./start`. On x86_64 WSL2 or when using an existing VS Code installation, install the **Microsoft C/C++** extension (`ms-vscode.cpptools`) in the environment where the project is open (in WSL, not on the Windows side). The Nix-managed x86_64 Linux editor already includes it.
2. Plug in the board and run **Tasks: Run Task → Flash Curiosity Nano**. Wait for the task to finish. Reflash after changing the firmware so the code on the board matches the ELF that GDB reads.
3. Set a breakpoint on a line the firmware will reach (for example, inside the blink loop). In **Run and Debug**, choose **Debug Curiosity Nano (already flashed)** and press **F5**. VS Code builds the ELF, checks for the programmer, starts Bloom, and attaches GDB. **F5 does not flash the board**, but Bloom resets it when attaching. Use **Stop** to end the session before flashing again.

If the pre-launch task can't see the board, check the cable and, in WSL2, USB forwarding. If the launch times out, check **Debug Console** for Bloom's messages, check the USB permissions, and close any other program using the board. Use a small number of breakpoints; the board has limited hardware breakpoint slots.

### From a terminal

1. Build and flash the current firmware as above. Wait for AVRDUDE to finish before starting Bloom; only one tool can use the programmer at a time.
2. From the repo root, start Bloom and leave it running:
   ```sh
   nix develop .#debug -c bloom
   ```
3. In a second terminal in the repo root, open the matching ELF in GDB:
   ```sh
   nix develop .#debug -c gdb build/avr128db48_project.elf
   ```
   At the GDB prompt:
   ```gdb
   target remote 127.0.0.1:1442
   info registers
   step
   ```
   `detach` ends the debug session. Stop Bloom if it's still running before flashing again.

Bloom startup was checked without hardware; on-board attach and stepping still need a real-board test. The VS Code profile is for x86_64 Linux only. On macOS, use Microchip MPLAB X if you need live debugging with the onboard probe. For **offline ELF inspection** on Linux, the same GDB command works without Bloom or a board; try `info line main`.

## Maintenance

- `flake.lock` locks the immutable Nixpkgs release snapshot and its content hash. Use `nix flake update nixpkgs` deliberately and commit the updated lock only after validation.
- `nix flake check` builds the starter, checks the AVR architecture, dry-runs programming/verification, and runs `clangd --check`. Run it on each native host to validate runtime support. `nix flake check --all-systems --no-build` checks evaluation only.
- If CMake refers to an old container or Nix store path (e.g. after changing the pin), run `cmake --fresh --preset course` inside the shell. Remove the generated `build/` directory first if it still contains artifacts from a different generator. If clangd fails before the first configuration, build once and restart clangd.
