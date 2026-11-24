# MPT: AVR128DB48 development with Nix

Build and flash the **AVR128DB48 Curiosity Nano** without Docker or a separately installed AVR toolchain. The starter in `src/main.c` blinks the board's user LED (PB3). Edit it or add sources to the `firmware` target in `CMakeLists.txt`.

**Daily workflow:** open the course folder in VSCodium (`codium .`) or VS Code (`code .`), then press **Ctrl+Shift+B** (macOS: **⌘⇧B**) to rebuild after edits. The first Nix shell entry automatically configures and builds the firmware and links the pinned clangd binary. For first-time setup, follow the steps below.

## 1. Set up once

- **Linux and macOS:** follow the [Nix installation instructions](https://nix.dev/install-nix), then open a new terminal. Install [VSCodium](https://vscodium.com/) or [VS Code](https://code.visualstudio.com/) separately.
- **Windows 11:** install [WSL2](https://learn.microsoft.com/windows/wsl/install) (for example, `wsl --install -d Ubuntu`). Install Nix **inside** Ubuntu, not in PowerShell. Clone the course repo inside the Linux filesystem (e.g. `~/mpt`), not under `/mnt/c`.

Run `nix --version` to check the installation. The VS Code workspace scripts handle the Nix flags for you. If you also want to run `nix develop` or `nix flake check` directly, add this line to `~/.config/nix/nix.conf` (create the directory/file if missing):

```ini
extra-experimental-features = nix-command flakes
```

Alternatively, add `--extra-experimental-features 'nix-command flakes'` right after `nix` in the commands below. No AVR packages need to be installed globally. The first run downloads the pinned tools. A Nix `shellHook` then configures and builds the firmware if the ELF, HEX, or compilation database is missing. This happens in your checkout after the tools are available, not in a package's sandboxed `postInstall` phase. Shell entry never launches an editor, changes USB permissions, or flashes/touches a board.

## 2. Build firmware

From the repo root:

```sh
nix develop
```

The shell performs the initial configure and build automatically, including when entered through VS Code's workspace scripts. Later shell entries skip setup when all generated outputs are present. After editing sources, rebuild explicitly:

```sh
cmake --preset course
cmake --build --preset course
```

This produces `build/avr128db48_project.hex` for flashing and `build/avr128db48_project.elf` with symbols. The preset also generates `build/compile_commands.json` for clangd. VS Code starts the pinned clangd through `scripts/clangd`, even before you open the first Nix terminal. Shell entry also creates a direct link at `.nix-tools/clangd`; other editors can use it with the `--query-driver` argument from `.vscode/settings.json`. Type `exit` to leave the shell.

## 3. Open the editor

Run `nix develop` once from the repo root to prepare the initial build and clangd symlink, then `exit`.

**Linux desktop or macOS:** open the workspace in [VSCodium](https://vscodium.com/) (`codium .`) or VS Code (`code .`), outside Nix. Install the recommended **clangd** and **CDT GDB Debug Adapter** extensions when prompted. Both are open source and available on Open VSX. clangd provides language features; CDT connects GDB to PyAvrOCD. The editor and extensions are installed separately, not provided or pinned by the flake.

Trust the workspace to enable its tooling and terminal settings. New integrated terminals automatically enter `nix develop` using the workspace's **Course Nix shell** profile; build tasks also enter Nix through workspace scripts. If clangd was already running when you updated the workspace, run **clangd: Restart language server**. Press **Ctrl+Shift+B** (**⌘⇧B** on macOS) to configure and rebuild after edits. None of these steps flashes firmware.

**If the shell or build doesn't start on macOS:** fully quit the editor with **⌘Q** after installing Nix, then reopen the repo folder and confirm the workspace is trusted. Close any restored terminal and explicitly choose **Terminal: Create New Terminal (With Profile) → Course Nix shell**. The first launch may take a few minutes while Nix downloads the toolchain. If it still fails, run these in macOS Terminal from the repo root to see the error directly:

```sh
nix --version
./scripts/in-env
```

Once you're in the course shell, run `cmake --preset course && cmake --build --preset course`.

**Windows 11 / WSL2:** for a non-proprietary editor, run the Linux build of VSCodium inside WSL2 using [WSLg](https://learn.microsoft.com/windows/wsl/tutorials/gui-apps). For the Windows VS Code workflow, install VS Code and the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl). Run `code .` from the repo root in your WSL terminal. If Windows VS Code is not on your WSL `PATH`, use **WSL: Open Folder in WSL** from VS Code instead. Verify the bottom-left status shows **WSL**. Install the two recommended extensions **in WSL**, then use **Ctrl+Shift+B**. The same workspace terminal profile and scripts enter Nix inside WSL; the build, language server, and flashing tools come from `flake.lock` on all platforms.

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
| `x86_64-linux` | Firmware build, clangd and AVRDUDE dry-run tested. Use VSCodium or VS Code. |
| `aarch64-linux` | Shell evaluates; native execution and USB still need testing. Use VSCodium or VS Code. |
| `x86_64-darwin`, `aarch64-darwin` | Shell evaluates; native execution and USB still need testing. Use VSCodium or VS Code. Nixpkgs 26.05 is the last series supporting Intel Macs. |
| Windows 11 | Use the matching Linux shell in WSL2. Run Linux VSCodium via WSLg or use Windows VS Code with its WSL extension. USB forwarding and the full WSL flow still need testing. No native Windows flake output. |

The default shell provides AVR GCC/binutils and avr-libc (including AVR128DB48 headers and startup code), CMake, Ninja, Make, clangd/clang-format, Git, Python, socat, and AVRDUDE. `lsusb` is Linux-only; macOS has built-in USB diagnostics. The flake does not install an editor or VS Code extensions. Install those separately; clangd still provides language features using the pinned Nix toolchain.

## Optional: live debugging with PyAvrOCD

The optional `.#debug` shell provides **PyAvrOCD 2.0.0** and AVR-capable GDB on **Linux (x86_64 and ARM64)** and **macOS (Intel and Apple Silicon)**. `scripts/debug-server` selects the AVR128DB48 Curiosity Nano's onboard nEDBG probe over UPDI. The GDB server listens only on `127.0.0.1:1442`. PyAvrOCD is not included in the default shell. WSL2 requires USB forwarding; on macOS, approve the USB accessory prompt if it appears.

### In VSCodium or VS Code

1. Open the project in VSCodium or VS Code. Install [**CDT GDB Debug Adapter**](https://open-vsx.org/extension/eclipse-cdt/cdt-gdb-vscode) (`eclipse-cdt.cdt-gdb-vscode`) in the environment where the project is open (in WSL, not on the Windows side). No Microsoft C/C++ extension is needed.
2. Plug in the board and set a breakpoint on a line the firmware will reach (for example, inside the blink loop).
3. In **Run and Debug**, select **Flash and Debug Curiosity Nano** and click the green play button or press **F5**. **This overwrites the firmware on the board every time.** The editor builds the firmware, checks for the programmer, waits for AVRDUDE to flash and verify it, then starts PyAvrOCD and connects GDB. Use **Stop** to end the session before flashing again. To flash without debugging, use **Tasks: Run Task → Flash Curiosity Nano**.

If the pre-launch task can't see the board, check the cable and, in WSL2, USB forwarding. If the launch times out, check **Debug Console** for PyAvrOCD's messages, check the USB permissions, and close any other program using the board. This profile uses only hardware breakpoints, so keep the number of breakpoints small.

### GDB commands in the Debug Console

With the target paused, prefix GDB commands with `>` in the Debug Console (for example, `>info registers`). Eclipse CDT does not use the `exec` or `-exec` prefix. For ordinary expressions, pause and select a frame in **Call Stack**; without a selected frame, CDT can report `Evaluation of expression without frameId is not supported.`

For example, `>set {unsigned char}0x800422 = 8` writes one byte to `PORTB.DIRCLR` (device address `0x0422` plus GDB's `0x800000` data offset), clearing PB3's output direction. To toggle the output latch instead, write to `PORTB.OUTTGL` at `0x800427`.

### Memory view

The workspace recommends Eclipse CDT's [**Memory Inspector**](https://open-vsx.org/extension/eclipse-cdt/memory-inspector) but does not install it automatically. In your editor's **Extensions** view, search for `@id:eclipse-cdt.memory-inspector` and click **Install**. In WSL or SSH, install it in the remote environment where the debugger runs.

1. Start debugging and pause at a breakpoint.
2. Run **Memory: Show Memory Inspector** from the Command Palette. You can also right-click a variable in the **Variables** view and select **Show in Memory Inspector**.
3. To inspect SRAM directly, enter `0x804000` as the start address. AVR GDB adds a `0x800000` offset to data addresses; the chip's SRAM starts at data address `0x4000`.

Board-level memory reads still need testing. Avoid browsing memory-mapped peripheral registers indiscriminately: some registers have side effects when read.

### From a terminal

1. Build and flash the current firmware as above. Wait for AVRDUDE to finish before starting PyAvrOCD; only one tool can use the programmer at a time.
2. From the repo root, start the same PyAvrOCD server that VS Code uses:
   ```sh
   ./scripts/debug-server
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
   `detach` ends the session and PyAvrOCD exits.

Native execution on macOS and on-board attach and stepping still need testing. For **offline ELF inspection**, the same GDB command works without PyAvrOCD or a board; try `info line main`.

## Maintenance

- `flake.lock` locks the immutable Nixpkgs release snapshot and its content hash. Use `nix flake update nixpkgs` deliberately and commit the updated lock only after validation.
- `nix flake check` builds the starter, checks the AVR architecture, dry-runs programming/verification, and runs `clangd --check`. Run it on each native host to validate runtime support. `nix flake check --all-systems --no-build` checks evaluation only.
- After changing `flake.lock`, run **clangd: Restart language server** in VS Code to pick up the new toolchain. If you use the direct `.nix-tools/clangd` link in another editor, open a new Nix shell first to refresh it.
