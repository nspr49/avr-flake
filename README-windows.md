# AVR course setup on Windows 11 (WSL2)

## Prerequisites

- [VS Code for Windows](https://code.visualstudio.com/) with the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl).
- Ubuntu on WSL2 and [usbipd-win](https://learn.microsoft.com/en-us/windows/wsl/connect-usb). Install them from **Administrator PowerShell**:

  ```powershell
  wsl --install -d Ubuntu
  winget install --interactive --exact dorssel.usbipd-win
  ```

  Restart if prompted, then open **Ubuntu** and create your Linux account.

## Set up the course in Ubuntu

1. In Ubuntu, run `sudo apt update && sudo apt install -y curl unzip`, then [install Nix](https://nix.dev/install-nix) **in Ubuntu** and open a fresh Ubuntu terminal. If `ps -p 1 -o comm=` doesn’t show `systemd`, [enable systemd](https://learn.microsoft.com/en-us/windows/wsl/systemd#how-to-enable-systemd) before running the USB setup.
2. Extract the course ZIP into your Ubuntu home folder, not under `/mnt/c`. If it’s in Windows Downloads, replace the username and ZIP filename below:

   ```sh
   unzip '/mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/avr-flake.zip' -d "$HOME/avr-flake"
   ```

3. In the extracted folder containing `flake.nix`, run:

   ```sh
   chmod +x .mpt/scripts/* .mpt/hardware/install-udev
   ./.mpt/hardware/install-udev
   ```

4. Run `wsl --shutdown` in PowerShell to apply USB group membership. Reopen Ubuntu, return to the course folder, and run `code .`. Trust the workspace and, in the **WSL: Ubuntu** window, click **Install** when prompted for the recommended extensions. Press **Ctrl+Shift+B** to build.

## Flash the board

1. Plug in the board and leave Ubuntu running. In PowerShell, run `usbipd list` and find the `BUSID` for `03eb:2175`. Use it in place of `4-4`:

   - **Administrator PowerShell**, once: `usbipd bind --busid 4-4`
   - **PowerShell**, after plugging in or restarting WSL: `usbipd attach --wsl --busid 4-4`

2. In the WSL VS Code window, choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
