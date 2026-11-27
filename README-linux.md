# AVR course setup on Linux

## Prerequisites

- [VS Code](https://code.visualstudio.com/)
- [Nix](https://nix.dev/install-nix). Open a new terminal after installing it.

## Setup

1. Extract the course ZIP and open a terminal in the extracted folder containing `flake.nix` (for example, `~/avr-flake`). Make the scripts executable and set up USB permissions:

   ```sh
   chmod +x .mpt/scripts/* .mpt/hardware/install-udev
   ./.mpt/hardware/install-udev
   ```

   The script prompts for `sudo`. After it finishes, sign out and back in so the new permissions take effect.
2. In VS Code, choose **File → Open Folder**, open that extracted folder, and trust the workspace. When prompted to install the [recommended workspace extensions](README.md#install-editor-extensions), click **Install**. Press **Ctrl+Shift+B** to build. The first build downloads the pinned tools.
3. Connect the Curiosity Nano with a USB data cable. In the Command Palette, choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
