# AVR course setup on Linux

1. Install [Nix](https://nix.dev/install-nix) and [VS Code](https://code.visualstudio.com/). Open a new terminal after installing Nix.
2. Extract the course ZIP and open a terminal in the extracted folder containing `flake.nix` (for example, `~/avr-flake`). Make the scripts executable and set up USB permissions:

   ```sh
   chmod +x .mpt/scripts/* .mpt/hardware/install-udev
   ./.mpt/hardware/install-udev
   ```

   The script prompts for `sudo`. After it finishes, sign out and back in so the new permissions take effect.
3. In VS Code, choose **File → Open Folder**, open that extracted folder, and trust the workspace. When prompted to install the [recommended workspace extensions](README.md#install-editor-extensions), click **Install**. Press **Ctrl+Shift+B** to build. The first build downloads the pinned tools.
4. Connect the Curiosity Nano with a USB data cable. In the Command Palette, choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
