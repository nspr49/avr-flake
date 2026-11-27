# AVR course setup on Windows 11 (WSL2)

## 1. Install WSL and VS Code

In **Administrator PowerShell**, run:

```powershell
wsl --install -d Ubuntu
winget install --interactive --exact dorssel.usbipd-win
```

Restart Windows if prompted. Open **Ubuntu** from the Start menu and create your Linux account. Install [VS Code for Windows](https://code.visualstudio.com/) and its [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl).

## 2. Set up the course in Ubuntu

Run `ps -p 1 -o comm=` in Ubuntu. If it does not print `systemd`, edit `/etc/wsl.conf` with `sudo nano /etc/wsl.conf` and add this setting (merge it into an existing `[boot]` section if present):

```ini
[boot]
systemd=true
```

If you changed the file, run `wsl --shutdown` in PowerShell, then reopen Ubuntu.

In Ubuntu, install curl and unzip, then follow the [Nix installation instructions](https://nix.dev/install-nix) **inside Ubuntu**, not in PowerShell:

```sh
sudo apt update && sudo apt install -y curl unzip
```

Open a fresh Ubuntu terminal after installing Nix. If the ZIP is in Windows Downloads, run the command below, substituting your Windows username and the ZIP's actual filename. Extract into your Ubuntu home directory, not under `/mnt/c`:

```sh
unzip '/mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/avr-flake.zip' -d "$HOME/avr-flake"
```

Go to the extracted folder containing `flake.nix` (inside `~/avr-flake`; the ZIP may contain another folder), then run:

```sh
chmod +x .mpt/scripts/* .mpt/hardware/install-udev
./.mpt/hardware/install-udev
```

Run `wsl --shutdown` in PowerShell again to pick up USB group membership. Reopen Ubuntu, return to the folder containing `flake.nix`, and run `code .` from there. Leave Ubuntu running.

Trust the workspace and confirm the bottom-left corner shows **WSL: Ubuntu**. In that WSL window, click **Install** when prompted to install the [recommended workspace extensions](README.md#install-editor-extensions). Press **Ctrl+Shift+B** to build; the first build downloads the pinned tools.

## 3. Pass the board through to WSL and flash

1. Connect the Curiosity Nano with a USB data cable. In PowerShell, run `usbipd list` and find the board by USB ID `03eb:2175`. Use its `BUSID` in place of `4-4` below.
2. In **Administrator PowerShell**, share the device once:

   ```powershell
   usbipd bind --busid 4-4
   ```

3. In PowerShell (administrator not required), attach the device to WSL:

   ```powershell
   usbipd attach --wsl --busid 4-4
   ```

   Repeat the attach command after unplugging the board or restarting WSL. Check `usbipd list` again in case the `BUSID` changed.
4. In the WSL-connected VS Code window, open the Command Palette and choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
